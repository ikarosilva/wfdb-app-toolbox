/*
 * ===========================================================
 * PhysioNet Challenge Score 2013
 *              
 * ===========================================================
 *
 * (C) Copyright 2013, by Ikaro Silva
 *
 * Project Info:
 *    Code: http://code.google.com/p/wfdb-app-toolbox/
 *    
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 *
 * Original Author:  Ikaro Silva, 
 * 
 * Last Modified:	 August 15, 2013
 * 
 * Changes
 * -------
 * Check: http://code.google.com/p/wfdb-java/list
 */ 

/** 
 * @author Ikaro Silva
 *  @version 1.0
 *  @since 1.0
 */
package org.physionet.wfdb;

import java.io.File;
import java.util.ArrayList;

public class Score2013 {

	private static final int logLevel=0;
	private static final String fSep=System.getProperty("file.separator");

	private static double score1(String recName,String refAnn,String testAnn,
								String T0, String TF){
		//Generate score1
		Wfdbexec tach=new Wfdbexec("tach",false);
		String[] refArg={"-r",recName,"-a",refAnn,"-f",T0,"-t",TF,"-n","12"};
		String[] testArg={"-r",recName,"-a",testAnn,"-f",T0,"-t",TF,"-n","12"};
		double[][] hrFQRS=null;
		double[][] hrTEST=null;
		double score2=0;
		try {
			hrFQRS=tach.execToDoubleArray(refArg);
			hrTEST=tach.execToDoubleArray(testArg);
		} catch (Exception e) {
			System.err.println("Could not score event 2 on entry: " + testAnn);
			e.printStackTrace();
		}

		//Calculate MSE for the score, TACH returns two vectors,
		//We want to calculate the MSE over the second column (HR estimates)
		//and we purposely omit the first 2 samples from the calculation
		for(int n=2;n< hrTEST.length;n++){
			score2=( (n-2)*score2 + 
					(hrTEST[n][0] - hrFQRS[n][0])*(hrTEST[n][0] - hrFQRS[n][0]) )/(n-1);
		}
		return score2;
	}

	private static String generateRR(String recName,String annName){

		Wfdbexec ann2rr=new Wfdbexec("ann2rr",Wfdbexec.customArchFlag);
		Wfdbexec patch=new Wfdbexec("patchann",Wfdbexec.customArchFlag);
		String[] ann2rrArg={"-r",recName,"-a",annName,"-c","-V"};
		patch.setLogLevel(logLevel);
		ann2rr.setLogLevel(logLevel);
		String rrName=null;
		String header="[LWEditLog-1.0] Record " + recName + ", annotator rr_"
				+  annName +" (1000 samples/second)";
		double[][] rr=null;
		try {
			rr=ann2rr.execToDoubleArray(ann2rrArg);
		} catch (Exception e) {
			System.err.println("Could not generate RR series for entry: " + annName);
			e.printStackTrace();
		}


		//Generate argument list for patchann
		//Suppressing warning because currently the API expects us to do somethign 
		//with the output, but in this case a file gets generated
		@SuppressWarnings("unused") 
		ArrayList<String> res=null;
		String[] rrData=new String[rr.length+2];
		rrData[0]=header;
		rrData[1]="";//Second header line should be empty according to patchann.c
		//System.out.println(rrData[0]);
		//System.out.println(rrData[1]);
		for(int n=0;n<rr.length;n++){
			rrData[n+2]=Integer.toString((int) rr[n][0]) 
					+ ",=,"+Integer.toString((int) rr[n][1]);
			//System.out.println(rrData[n+2]);
		}

		try {
			patch.setArguments(null);//patch takes no  arguments;
			res = patch.execWithStandardInput(rrData);
			rrName="rr_" + annName;
		} catch (Exception e) {
			System.err.println("Could not generate patch for entry: " + annName);
			e.printStackTrace();
		}	
		//Return the pathname if sucessfull
		return rrName;
	}
	
	private static String score2(String recName,String rrAnn,String rrTest,
								String T0, String TF){
		Wfdbexec mxm=new Wfdbexec("mxm",Wfdbexec.customArchFlag);
		String[] arg={"-r",recName,"-a",rrAnn,rrTest,
				"-f",T0,"-t",TF};
		mxm.setArguments(arg);
		mxm.setLogLevel(logLevel);
		ArrayList<String> ans=null;
		try {
			ans = mxm.execToStringList();
		} catch (Exception e) {
			System.err.println("Could not generate RR series for entry: " + rrTest);
			e.printStackTrace();
		}
		String score=null;
		int cutPoint;
		for(String tmp: ans){
			if(tmp.contains("Normalized RMS error:")){
				tmp=tmp.replaceAll("Normalized RMS error:","");
				cutPoint=tmp.indexOf("%");
				score=tmp.substring(0,cutPoint-1);
				break;
			}
		}
		return score;
	}

	public static double[] getScore(String[] args) throws Exception {

		// Parse input arguments
		if(args.length != 4){
			System.out.println("Usage: org.physionet.wfdb.Score2013 recName dataDir refAnn testAnn");
			System.out.println("\trecName = String name of WFDB record");
			System.out.println("\tdataDir = Full path of the current direcotry, where the data and annotions should be");
			System.out.println("\trefAnn = String name of WFDB reference annotation file");
			System.out.println("\ttestAnn = String name of your WFDB test annotation file");
			return null;
		}
		String recName=args[0];
		String dataDir=args[1];
		String refAnn=args[2];
		String testAnn=args[3];	

		//Get first and last reference annotations
		//Output should be in a format similar to: "0:01.384"
		Wfdbexec rdann=new Wfdbexec("rdann",Wfdbexec.customArchFlag);
		String[] annArg={"-r",recName,"-a",refAnn};
		ArrayList<String> refAnnSamples= new ArrayList<String>();
		refAnnSamples=rdann.execToStringList(annArg);
		
		String[] T0=refAnnSamples.get(0).split("\\s+");;
		String[] TF=refAnnSamples.get(refAnnSamples.size()-1).split("\\s+");;;
		
		double[] score = new double[2];

		//Generate HR score
		score[0]=score1(recName,refAnn,testAnn,T0[1],TF[1]);

		//Generate RR series
		
		//Delet any old cache file and generate new RR files
		String rrRefFile="rr_"+refAnn;
		File refFile=new File(dataDir+fSep+recName+"."+ rrRefFile);
		//Delete temporary file it exists already
		if(refFile.isFile()){
			if(! refFile.delete()){
    		    System.err.println("Could not remove existing cache file:" 
			+ refFile);
    		}
		}
		rrRefFile=generateRR(recName,refAnn);
		
		String rrTestFile="rr_"+testAnn;
		File testFile=new File(dataDir+fSep+recName+"."+ rrTestFile);
		if(testFile.isFile()){
			if(! testFile.delete()){
    		 System.err.println("Could not remove existing cache file:"
			+ testFile);
    		 System.err.println("Cannot score entry without generating a "+
			" clean cache file. Please remove old file:" + testFile);
    		 return null;
    		}
		}
		rrTestFile=generateRR(recName,testAnn);

		
		if(rrRefFile != null && rrTestFile != null){
			//Calculate the error
			score[1]=Double.valueOf(score2(recName,rrRefFile,rrTestFile,T0[1],TF[1]));
			//Perform clean up of cached files
			if(! testFile.delete()){
	    		 System.err.println("Could not remove cache file:"
	    				 + testFile);
	    		 System.err.println("Pleaes remove them manually.");
	    		}
			if(! refFile.delete()){
    		    System.err.println("Could not remove cache file:" 
    		    		+ refFile);
    		    System.err.println("Pleaes remove them manually.");
    		}
		}	
		return score;

	}

	public static void main(String[] args) throws Exception {

		double[] score = new double[2];
		score=getScore(args);
		System.out.println("Score (event 1/4): " + score[0]);
		System.out.println("Score (event 2/5): " + score[1]);
	}


}
