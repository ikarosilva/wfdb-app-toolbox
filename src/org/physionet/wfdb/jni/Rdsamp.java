/* Wrapper to Java Native Interface implementation of rdsamp.c :
 *
 *http://www.physionet.org/physiotools/wfdb/app/rdsamp.c
 *
 *The modification are done in order to make it compatible and
 *efficient when called through JNI.
 *
 *Created by Ikaro Silva 2015
 *
 *
 */
package org.physionet.wfdb.jni;

public class Rdsamp {
	long nSamples;
	int[] baseline;
	double[] gain;
	double fs;
	int nsig;
	int[] rawData;
	String recordName;
	
	//Initialize enviroment
	static {
		org.physionet.wfdb.SystemSettings.loadLib("wfdb");
		org.physionet.wfdb.SystemSettings.loadLib("rdsampjni");
	}
	
	public static void main(String[] args){
		Rdsamp myRdsamp=new Rdsamp();
		myRdsamp.readData(args);
		for(int i=0;i<myRdsamp.rawData.length;i++)
			System.out.println(myRdsamp.rawData[i]);
		myRdsamp=null;
	}
	
	public int[] exec(String[] args) {
		readData(args);
		return rawData;
	}

	//Utility functions, not be be used by other classes
	private native void getData(String[] args);
	
	private void setBaseline(int[] newBaseline){
		baseline=newBaseline;
	}
	private void setGain(double[] newGain){
		gain=newGain;
	}
	private void setRawData(int[] newRawData){
		rawData=newRawData;
	}
	private void setRecordName(String recName){
		recordName=recName;
	}
	
	//Public interface
	public void readData(String[] args){
		setRecordName(args[1]);
		getData(args);
	}
	
	public int[] getBaseline(){
		return baseline;
	}
	
	public double getFs(){
		return fs;
	}
	
	public long getNSamples(){
		return nSamples;
	}
	
	public int getNsig(){
		return nsig;
	}
	
	public double[] getGain(){
		return gain;
	}
	
	public String getRecordName(){
		return recordName;
	}
	
	public void reset(){
		
		nSamples=-1;
		fs=-1;
		baseline=null;
		nsig=-1;
		gain=null;
		rawData=null;
		recordName=null;
	}
	
}