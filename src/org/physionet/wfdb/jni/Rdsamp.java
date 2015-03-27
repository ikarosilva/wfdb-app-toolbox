package org.physionet.wfdb.jni;

public class Rdsamp {
	long nSamples;
	int baseline;
	double gain;
	double fs;
	
	public native void getData();
	static {
		System.loadLibrary("rdsampjni");
	}
	public static void main(String[] args) {
		Rdsamp myRdsamp = new Rdsamp();
		myRdsamp.getData();
		System.out.println("Samples Read: " + myRdsamp.nSamples);
		System.out.println("Fs: " + myRdsamp.fs);
		System.out.println("baseline: " + myRdsamp.baseline);
		System.out.println("gain: " + myRdsamp.gain);
	}
	
	public long getnSamples(){
		return nSamples;
	}
	
	public double getGain(){
		return gain;
	}
	
	public int getBaseline(){
		return baseline;
	}
	
	public double getFs(){
		return fs;
	}
}