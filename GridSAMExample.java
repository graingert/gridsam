import java.io.IOException;
import java.io.InputStream;

import org.icenigrid.gridsam.client.common.ClientSideJobManager;

import org.icenigrid.gridsam.core.JobInstance;
import org.icenigrid.gridsam.core.JobManagerException;
import org.icenigrid.gridsam.core.SubmissionException;
import org.icenigrid.gridsam.core.UnknownJobException;
import org.icenigrid.gridsam.core.UnsupportedFeatureException;
import org.icenigrid.gridsam.core.jsdl.JSDLSupport;
import org.icenigrid.schema.jsdl.y2005.m11.JobDefinitionDocument;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Text;
import org.w3c.dom.ls.DOMImplementationLS;
import org.w3c.dom.ls.LSSerializer;
import org.xml.sax.SAXException;

import org.apache.xmlbeans.XmlException; 

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import static org.joox.JOOX.$;

public class GridSAMExample {

	private static String ftpServer = System.getProperty("ftp.server");
	private static String gridsamServer = System.getProperty("gridsam.server");

	public static void main(String[] args)
		throws JobManagerException, SubmissionException, UnsupportedFeatureException, UnknownJobException,
			IOException, XmlException, InterruptedException {
		
		System.out.println("Creating a new client Job Manager...");
		ClientSideJobManager jobManager = new ClientSideJobManager(
			new String[] { "-s", gridsamServer },
			ClientSideJobManager.getStandardOptions());

		System.out.println("Creating JSDL description...");
		String xJSDLString  = createJSDLDescription("/usr/bin/sort", "/etc/hosts");
		

		System.out.println(xJSDLString);

		JobDefinitionDocument xJSDLDocument =
			JobDefinitionDocument.Factory.parse(xJSDLString);

		System.out.println("Submitting job to Job Manager...");
		JobInstance job = jobManager.submitJob(xJSDLDocument);
		String jobID = job.getID();

		// Get and report the status of job until complete
		System.out.println("Job ID: " + jobID);

		// ...
	}

	private static String createJSDLDescription(String execName, String args) {
		String s_jsdl = "";
		try {
			InputStream in = GridSAMExample.class.getResourceAsStream("posix.jsdl");
			DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
			DocumentBuilder db;
			db = dbf.newDocumentBuilder();
			Document jsdl = db.parse(in);
			
			$(jsdl).find("#execName").text(execName).removeAttr("id");
			$(jsdl).find("#args").text(args).removeAttr("id");
			$(jsdl).find("URI.ftp").text("ftp://anonymous:anonymous@127.0.0.1:55521").removeAttr("class");
			
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
