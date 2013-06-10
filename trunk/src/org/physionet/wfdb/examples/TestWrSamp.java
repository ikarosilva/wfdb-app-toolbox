package org.physionet.wfdb.examples;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Map;

import org.physionet.wfdb.InputWriter;
import org.physionet.wfdb.OutputReader;

public class TestWrSamp extends Thread {

	Process process = null;
	ArrayList<String> commandInput;
	String[] data;
	ProcessBuilder pb;
	protected static Map<String,String> env;

	TestWrSamp(String[] data) {
		commandInput= new ArrayList<String>();
		/*
		commandInput.add("head");
		commandInput.add("-n");
		commandInput.add("30");
		 */

		commandInput.add("./wrsamp");
		commandInput.add("-c");
		commandInput.add("-z");
		commandInput.add("-o");
		commandInput.add("ikaro");
		commandInput.add("-F");
		commandInput.add("1000");
		commandInput.add("-G");
		commandInput.add("200");
		commandInput.add("-O");
		commandInput.add("16");

		pb = new ProcessBuilder(commandInput);
		pb.redirectErrorStream(true);
		pb.directory(new File("/afs/ecg.mit.edu/user/ikaro/home/common_linux/workspace/" +
				"PhysioNet2013Challenge/mcode/nativelibs/linux-amd64/"));
		env = pb.environment();
		env.put("LD_LIBRARY_PATH","/afs/ecg.mit.edu/user/ikaro/home/common_linux/workspace/" +
				"PhysioNet2013Challenge/mcode/nativelibs/linux-amd64/");
		this.data=data;
	}

	public void run(){
		int exitStatus;
		try {
			System.err.println("TEST: starting process.");
			process = pb.start();
			OutputReader or= new OutputReader(process.getInputStream()) ;
			InputWriter iw= new 
					InputWriter(process.getOutputStream(), data);
			iw.start();
			or.start();
			iw.join();
			or.join();
			exitStatus=process.waitFor();
			if(exitStatus != 0 ){
				System.err.println("Process exited with error code="
						+ exitStatus);
			}else{
				System.err.println("TEST: process.finished");
			}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}



	public static void main(String[] args) {

		String[] data=new String[30];
		data[0]="0     -33     -67      30     -35";
		data[1]="1     -38     -67      30     -35";
		data[2]="2     -44     -68      32     -35";
		data[3]="3     -50     -69      32     -36";
		data[4]="4     -56     -69      33     -37";
		data[5]="5     -62     -69      34     -39";
		data[6]="6     -68     -70      34     -40";
		data[7]="7     -74     -71      35     -42";
		data[8]="8     -80     -72      35     -43";
		data[9]="9     -86     -73      35     -45";
		data[10]="10     -90     -74      35     -46";
		data[11]="11     -94     -75      36     -48";
		data[12]="12     -98     -77      36     -50";
		data[13]="13    -102     -80      37     -53";
		data[14]="14    -105     -83      38     -57";
		data[15]="15    -108     -85      39     -61";
		data[16]="16    -111     -88      40     -63";
		data[17]="17    -114     -90      42     -65";
		data[18]="18    -116     -91      43     -65";
		data[19]="19    -119     -93      44     -66";
		data[20]="20    -122     -94      45     -66";
		data[21]="21    -126     -94      46     -67";
		data[22]="22    -129     -93      47     -66";
		data[23]="23    -132     -91      48     -64";
		data[24]="24    -135     -89      49     -59";
		data[25]="25    -138     -88      51     -53";
		data[26]="26    -142     -85      51     -47";
		data[27]="27    -146     -81      52     -41";
		data[28]="28    -150     -77      53     -36";
		data[29]="29    -153     -72      54     -32";
		TestWrSamp myTest=new TestWrSamp(data);


		myTest.start();
	}

}


