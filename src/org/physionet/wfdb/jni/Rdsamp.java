package org.physionet.wfdb.jni;

class Rdsamp {
	public native void getData();

	
	static {
		System.loadLibrary("rdsampjni");
	}
	
	public static void main(String[] args) {
		Rdsamp myRdsamp = new Rdsamp();
		System.out.println("testing Rdsamp...");
		myRdsamp.getData();
		System.out.println("Done testing Rdsamp...");
	}
}