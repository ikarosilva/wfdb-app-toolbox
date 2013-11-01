package org.physionet.wfdb;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;

public class InputWriter extends Thread{

	String[] inputData;
	OutputStream os;
	String newLine;

	public InputWriter(OutputStream os, String[] inputData){
		this.os=os;
		this.inputData=inputData;
		newLine = System.getProperty("line.separator");
	}
	public void run(){
		try {
			OutputStreamWriter osw= new OutputStreamWriter(os);
			BufferedWriter bw= new BufferedWriter(osw);
			for(int i=0;i<inputData.length;i++){
					bw.write(inputData[i] + newLine);
			}
			bw.flush();
			bw.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
