import org.icenigrid.gridsam.client.common.ClientSideJobManager;
import org.icenigrid.gridsam.core.*;
import org.icenigrid.gridsam.core.jsdl.JSDLSupport;
import org.icenigrid.schema.jsdl.y2005.m11.*; 

import org.apache.xmlbeans.XmlException; 

import java.io.*;
import java.util.*;

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
		String xJSDLString  = createJSDLDescription("/bin/sort", "/etc/hosts");
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
		return "";
	}
}
