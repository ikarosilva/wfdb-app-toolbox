package org.physionet.wfdb;

import java.io.BufferedWriter;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;

public class InputWriter extends Thread{

	String[] inputData;
	byte[] inputDataBytes;
	OutputStream os;
	String newLine;

	public InputWriter(OutputStream os, String[] inputData){
		this.os=os;
		this.inputData=inputData;
		inputDataBytes=null;
		newLine = System.getProperty("line.separator");
	}

	public InputWriter(OutputStream os, byte[] inputData){
		this.os=os;
		this.inputDataBytes=inputData;
		inputData=null;
		newLine = System.getProperty("line.separator");
	}

	public void run(){
		try {
			if(inputDataBytes == null){
				OutputStreamWriter osw= new OutputStreamWriter(os);
				BufferedWriter bw= new BufferedWriter(osw);
				for(int i=0;i<inputData.length;i++){
					bw.write(inputData[i] + newLine);
				}
				bw.flush();
				bw.close();
			}else{
				//Passing a byte stream through standard input
				DataOutputStream dw= new DataOutputStream (os);
				dw.write(inputDataBytes,0,inputDataBytes.length);
				dw.flush();
				dw.close();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
