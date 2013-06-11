package org.physionet.wfdb.examples;

import java.util.ArrayList;

import org.physionet.wfdb.Wfdbexec;

public class QRSDetectionEx1 {

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		//TODO: Fix issues with WFDB path not being properly set
		Wfdbexec wqrsDetector=new Wfdbexec("wqrs");
		Wfdbexec rdann=new Wfdbexec("rdann");

		//Define arguments, annotate (find QRS complexes) from the mitdb/100 record
		String[] arg1={"-r","mitdb/100"};
		String[] arg2={"-r","mitdb/100","-a","wrqs"};
		String annPath=System.getProperty("user.dir") +
				System.getProperty("file.separator");

		//Set the annotation to be in the WFDB Path
		rdann.setWFDBPATH(annPath+":.:http://www.physionet.org/physiobank/database:");

		//Execute command
		ArrayList<String> x= new ArrayList<String>(); 
		try {
			System.out.println("Calculating QRS peaks. Annotation file will be saved at:");
			System.out.println(annPath);
			wqrsDetector.execToStringList(arg1);
			System.out.println("Reading annotation and printing peak locations:");
			x=rdann.execToStringList(arg2);
			for(String tmpStr : x){
				System.out.println(tmpStr);
			}	
		} catch (Exception e) {
			System.err.println("Could not execute command:" + e);
		}

	}

}
