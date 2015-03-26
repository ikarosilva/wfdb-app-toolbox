package org.physionet.wfdb.jni;

public class Rdsamp {
	long nSamples;
	int baseline;
	int gain;
	
	public native void getData();
	static {
		System.loadLibrary("rdsampjni");
	}
	public static void main(String[] args) {
		Rdsamp myRdsamp = new Rdsamp();
		myRdsamp.getData();
		System.out.println("Samples Read: " + myRdsamp.nSamples);
	}
}