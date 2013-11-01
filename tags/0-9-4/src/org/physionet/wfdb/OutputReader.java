package org.physionet.wfdb;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;

public class OutputReader extends Thread {
	InputStream is;
	ArrayList<String> results;

	public OutputReader(InputStream is){
		this.is=is;
		results= new ArrayList<String>(); 
	}
	public void run(){
		try {
			InputStreamReader isr= new InputStreamReader(is);
			BufferedReader br = new BufferedReader(isr);
			String line = null;
			while ( ( line = br.readLine() )!= null ){
				results.add(line);
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	public ArrayList<String> getResults(){
		return results;
	}
}