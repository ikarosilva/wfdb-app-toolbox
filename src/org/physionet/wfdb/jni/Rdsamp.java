package org.physionet.wfdb.jni;

public class Rdsamp {
	long nSamples;
	int[] baseline;
	double[] gain;
	double fs;
	int nsig;
	int[] rawData;
	
	static {
		System.loadLibrary("rdsampjni");
	}
	
	public static void main(String[] args) {
		Rdsamp myRdsamp = new Rdsamp();
		myRdsamp.readData();
	}

	//Utility functions, not be be used by other classes
	private native void getData();
	private void setBaseline(int[] newBaseline){
		baseline=newBaseline;
	}
	private void setGain(double[] newGain){
		gain=newGain;
	}
	private void setRawData(int[] newRawData){
		rawData=newRawData;
	}
	
	//Public interface
	public void readData(){
		getData();
		System.out.println("Samples Read: " + nSamples);
		System.out.println("Fs: " + fs);
		System.out.println("nsig: " + nsig);
		for(int i=0;i< nsig;i++){
			System.out.print("baseline[" +i +"] =" + baseline[i]);
			System.out.println("\tgain[" +i +"] =" + gain[i]);
		}
		System.out.println("");
		for(int i=0;i< rawData.length;i++){
			System.out.println("data[" +i +"] =" + rawData[i]);
		}
	}
	
	public int[] getRawData(){
		return rawData;
	}
	
	public int[] getBaseline(){
		return baseline;
	}
	
	public double getFs(){
		return fs;
	}
	
	public long getnSamples(){
		return nSamples;
	}
	
	public double[] getGain(){
		return gain;
	}
	
	
}