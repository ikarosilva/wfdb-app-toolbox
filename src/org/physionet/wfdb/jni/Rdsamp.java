package org.physionet.wfdb.jni;

public class Rdsamp {
	long nSamples;
	int[] baseline;
	double gain;
	double fs;
	
	static {
		System.loadLibrary("rdsampjni");
	}
	
	public static void main(String[] args) {
		Rdsamp myRdsamp = new Rdsamp();
		myRdsamp.getData();
		System.out.println("Samples Read: " + myRdsamp.nSamples);
		System.out.println("Fs: " + myRdsamp.fs);
		System.out.println("gain: " + myRdsamp.gain);
		for(int i=0;i< myRdsamp.baseline.length;i++)
			System.out.println("baseline[" +i +"] =" + myRdsamp.baseline[i]);
		System.out.println("");
	}
	
	public int[] getFoo(){
		int[] foo={1,3};
		return foo;
	}
	
	public void setBaseline(int[] newBaseline){
		System.out.println("new baseline length="  + newBaseline.length);
		baseline=newBaseline;
		System.out.println("New baseline is: " + baseline.length);
	}
	
	public native void getData();
	
	public long getnSamples(){
		return nSamples;
	}
	
	public double getGain(){
		return gain;
	}
	
	public int[] getBaseline(){
		return baseline;
	}
	
	public double getFs(){
		return fs;
	}
}