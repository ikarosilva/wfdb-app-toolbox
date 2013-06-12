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
 * Last Modified:	 June 6, 2013
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

import java.util.ArrayList;

public class Score2013 {

	private static final int logLevel=0;

	private static double score1(String recName,String refAnn,String testAnn){
		//Generate score1
		Wfdbexec tach=new Wfdbexec("tach");
		String[] refArg={"-r",recName,"-a",refAnn,"-n","12"};
		String[] testArg={"-r",recName,"-a",testAnn,"-n","12"};
		double[][] hrFQRS=null;
		double[][] hrTEST=null;
		double score2=0;
		try {
			hrFQRS=tach.execToDoubleArray(refArg);
			hrTEST=tach.execToDoubleArray(testArg);
			if((hrTEST != null) && hrTEST.length != hrFQRS.length)
				throw new AssertionError("Annotation size do not match!");    
		} catch (Exception e) {
			System.err.println("Could not score event 2 on entry: " + testAnn);
			e.printStackTrace();
		}

		//Calculate MSE for the score, TACH returns two vectors,
		//We want to calculate the MSE over the second column (HR estimates)
		//and we purposely omit the first sample from the calculation
		for(int n=1;n< hrTEST.length;n++){
			score2=( (n-1)*score2 + 
					(hrTEST[n][0] - hrFQRS[n][0])*(hrTEST[n][0] - hrFQRS[n][0]) )/n;
		}
		return score2;
	}

	private static String generateRR(String recName,String annName){

		Wfdbexec ann2rr=new Wfdbexec("ann2rr");
		Wfdbexec patch=new Wfdbexec("patchann");
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

	private static String score2(String recName,String rrAnn,String rrTest){
		Wfdbexec mxm=new Wfdbexec("mxm");
		String[] arg={"-r",recName,"-a",rrAnn,rrTest,
				"-f","0"};
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

	public static double[] getScore(String[] args) {

		// Parse input arguments
		if(args.length != 3){
			System.out.println("Usage: org.physionet.wfdb.Score2013 recName refAnn testAnn");
			System.out.println("\trecName = String name of WFDB record");
			System.out.println("\trefAnn = String name of WFDB reference annotation file");
			System.out.println("\ttestAnn = String name of your WFDB test annotation file");
			return null;
		}
		String recName=args[0];
		String refAnn=args[1];
		String testAnn=args[2];	
		double[] score = new double[2];

		//Generate HR score
		score[0]=score1(recName,refAnn,testAnn);
		
		//Generate RR series
		String rrRefFile=generateRR(recName,refAnn);
		
		String rrTestFile=generateRR(recName,testAnn);
		if(rrRefFile != null && rrTestFile != null){
			//Calculate the error
			score[1]=Double.valueOf(score2(recName,rrRefFile,rrTestFile));
		}	
		return score;

	}

	public static void main(String[] args) {

		double[] score = new double[2];
		score=getScore(args);
		System.out.println("Score (event 1/4): " + score[0]);
		System.out.println("Score (event 2/5): " + score[1]);
	}

	
	




}
