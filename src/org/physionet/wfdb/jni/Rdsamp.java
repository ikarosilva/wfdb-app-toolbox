package org.physionet.wfdb.jni;

import java.util.ArrayList;

public class Rdsamp {
	long nSamples;
	ArrayList<Integer> baseline;
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
		System.out.println("baseline: " + myRdsamp.baseline);
		System.out.println("gain: " + myRdsamp.gain);
	}
	
	public native void getData();
	
	public long getnSamples(){
		return nSamples;
	}
	
	public double getGain(){
		return gain;
	}
	
	public ArrayList<Integer> getBaseline(){
		return baseline;
	}
	
	public double getFs(){
		return fs;
	}
}