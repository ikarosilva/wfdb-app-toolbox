package org.physionet.wfdb.jni;

public class Rdsamp {
	long nSamples;
	int[] baseline;
	double[] gain;
	double fs;
	int nsig;
	
	static {
		System.loadLibrary("rdsampjni");
	}
	
	public static void main(String[] args) {
		Rdsamp myRdsamp = new Rdsamp();
		myRdsamp.getData();
		System.out.println("Samples Read: " + myRdsamp.nSamples);
		System.out.println("Fs: " + myRdsamp.fs);
		System.out.println("nsig: " + myRdsamp.nsig);
		for(int i=0;i< myRdsamp.nsig;i++){
			System.out.print("baseline[" +i +"] =" + myRdsamp.baseline[i]);
			System.out.println("\tgain[" +i +"] =" + myRdsamp.gain[i]);
		}
		System.out.println("");
	}
	
	public void setBaseline(int[] newBaseline){
		baseline=newBaseline;
	}
	
	public void setGain(double[] newGain){
		gain=newGain;
	}
	
	public native void getData();
	
	public long getnSamples(){
		return nSamples;
	}
	
	public double[] getGain(){
		return gain;
	}
	
	public int[] getBaseline(){
		return baseline;
	}
	
	public double getFs(){
		return fs;
	}
}