package org.physionet.wfdb.examples;

import org.physionet.wfdb.Wfdbexec;

public class RdsampEx1 {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		Wfdbexec rdsamp=new Wfdbexec("rdsamp");
		
		//Define arguments to read 5 samples from mitdb/100
		String[] arguments={"-r","mitdb/100","-t","s5"};

		//Execute command
		double[][] x=null;
		try {
			x=rdsamp.execToDoubleArray(arguments);
			for(int i=0;i<x.length;i++){
				for(int k=0;k<x[0].length;k++)
					System.out.println("x[" + i+" , " + k +" ] =" + x[i][k]);
			}
		} catch (Exception e) {
			System.err.println("Could not execute command:" + e);
		}

	}

}
