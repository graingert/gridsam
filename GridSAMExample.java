import java.lang.Integer;
import java.io.IOException;
import java.io.InputStream;
import java.io.File;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Map;


import org.icenigrid.gridsam.client.common.ClientSideJobManager;

import org.icenigrid.gridsam.core.JobInstance;
import org.icenigrid.gridsam.core.JobManagerException;
import org.icenigrid.gridsam.core.JobStage;
import org.icenigrid.gridsam.core.SubmissionException;
import org.icenigrid.gridsam.core.UnknownJobException;
import org.icenigrid.gridsam.core.UnsupportedFeatureException;
import org.icenigrid.schema.jsdl.y2005.m11.JobDefinitionDocument;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Text;
import org.w3c.dom.ls.DOMImplementationLS;
import org.w3c.dom.ls.LSSerializer;
import org.xml.sax.SAXException;

import org.apache.xmlbeans.XmlException; 

import org.apache.commons.io.FileUtils;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;


import static org.joox.JOOX.$;

public class GridSAMExample {

	private static String ftpServer = System.getProperty("ftp.server");
	private static String gridsamServer = System.getProperty("gridsam.server");
	private static ClientSideJobManager jobManager;
	private static String theWord = "the";

	@SuppressWarnings("unchecked")
	public static void main(String[] args)
		throws JobManagerException, SubmissionException, UnsupportedFeatureException, UnknownJobException,
			IOException, XmlException, InterruptedException {
		
		System.out.println("Creating a new client Job Manager...");
		jobManager = new ClientSideJobManager(
			new String[] { "-s", gridsamServer },
			ClientSideJobManager.getStandardOptions());

		ArrayList<File> files = new ArrayList<File>();
		files.add(new File("/home/tag1g09/projects/lsds/gridsam-2.3.0-client/cw-file1.txt"));
		files.add(new File("/home/tag1g09/projects/lsds/gridsam-2.3.0-client/cw-file2.txt"));
		files.add(new File("/home/tag1g09/projects/lsds/gridsam-2.3.0-client/cw-file3.txt"));
		files.add(new File("/home/tag1g09/projects/lsds/gridsam-2.3.0-client/cw-file3.txt"));

		System.out.println(MapReduce(files));
	}

	public static Map<File, Integer> MapReduce(List<File> inputList){
		Map<File, List<String>> intermediateList = GridSamMap(inputList);
		return reduce(intermediateList);
	}

	public static Map<File, Integer> reduce(Map<File, List<String>> intermediateMap){
		Map<File, Integer> outputMap = new HashMap<File,Integer>();
		for (Map.Entry<File,List<String>> entry : intermediateMap.entrySet()){
			int total = reduceFunction(entry.getValue());
			outputMap.put(entry.getKey(), new Integer(total));
		}
		return outputMap;
	}




	public static int reduceFunction(List<String> list){
		int totalCount = 0;
		for (String str : list){
			totalCount += Integer.parseInt(str.replaceAll("\\s",""));
		}
		return totalCount;
	}

	public static Map<File, List<String>> GridSamMap(List<File> inputList){
		Map<File, List<String>> outputMap = new HashMap<File,List<String>>();
		List<String> jobList = new ArrayList<String>();
		Map<File, File> realToOutputMap = new HashMap<File,File>();

		
		for (File file : inputList){
			

			try {


				File tmp = File.createTempFile("output", null, new File("/home/tag1g09/projects/lsds/gridsam-2.3.0-client/examples/"));
				realToOutputMap.put(file,tmp);

				String ftpName = "ftp://anonymous:anonymous@127.0.0.1:55521/" + tmp.getName();


				File hostedInputFileLocation = gridCopyToDataServer(file);

				String jobID = gridSubmit("/bin/grep", "-cw " + theWord + " " + hostedInputFileLocation, ftpName);
				jobList.add(jobID);



			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} 


		}

		while (!JobsDone(jobList)){

		}

		//Add all the items to the output Map.
		//Using a map here saves time later
		for(File file : inputList){
			if (!outputMap.containsKey(file)){
				outputMap.put(file, new ArrayList<String>());
			}

			outputMap.get(file).add(gridCopyFromDataServer(realToOutputMap.get(file)));
		}

		return outputMap;
	}


	private static boolean JobsDone(List<String> jobList){
		for (String jobID : jobList){
			if (!gridJobFinished(jobID)){
				return false;
			}
		}
		return true;
	}

	private static File gridCopyToDataServer(File file){
		try {
			File tmp = File.createTempFile("input", null, new File("/home/tag1g09/projects/lsds/gridsam-2.3.0-client/examples/"));
			FileUtils.copyFile(file, tmp);
			return tmp;
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return new File("");
	}

	private static String gridCopyFromDataServer(File file){
		try{
			return FileUtils.readFileToString(file);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return "";
	}

	private static String gridSubmit(String execName, String args, String ftpName){
		try{
			String xJSDLString  = createJSDLDescription(execName, args, ftpName);

			JobDefinitionDocument xJSDLDocument =
				JobDefinitionDocument.Factory.parse(xJSDLString);

			JobInstance job = jobManager.submitJob(xJSDLDocument);
			System.out.println(job.getID());
			return job.getID();
		} catch (XmlException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return "";
	}

	private static boolean gridJobFinished(String jobID){
		try{
			JobInstance job = jobManager.findJobInstance(jobID);
			return job.getLastKnownStage().getState().isTerminal();
		} catch (Exception e){
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		return false;
	}

	private static String createJSDLDescription(String execName, String args, String ftpName) {
		String s_jsdl = "";
		try {
			InputStream in = GridSAMExample.class.getResourceAsStream("posix.jsdl");
			DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
			DocumentBuilder db;
			db = dbf.newDocumentBuilder();
			Document jsdl = db.parse(in);
			
			$(jsdl).find("#execName").text(execName).removeAttr("id");
			$(jsdl).find("#args").text(args).removeAttr("id");
			$(jsdl).find("#ftpName").text(ftpName).removeAttr("id");


		    DOMImplementationLS domImplementation = (DOMImplementationLS) jsdl.getImplementation();
		    LSSerializer lsSerializer = domImplementation.createLSSerializer();
		    s_jsdl = lsSerializer.writeToString(jsdl); 

		} catch (ParserConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (SAXException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return s_jsdl;
	}
}
