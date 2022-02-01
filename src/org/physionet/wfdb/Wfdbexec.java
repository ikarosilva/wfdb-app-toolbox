/* ===========================================================
 * WFDB Java : Interface to WFDB Applications.
 *              
 * ===========================================================
 *
 * (C) Copyright 2012, by Ikaro Silva
 *
 * Project Info:
 *    Code: https://code.google.com/p/wfdb-java/
 *    WFDB: https://archive.physionet.org/physiotools/wfdb.shtml
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 *
 * Original Author:  Ikaro Silva
 * Contributor(s):   Daniel J. Scott;
 *
 * Changes
 * -------
 * Check: http://code.google.com/p/wfdb-java/list
 */ 

/** 
 * @author Ikaro Silva
 *  @version 1.0
 *  @since 1.0
 */



package org.physionet.wfdb;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.physionet.wfdb.jni.Rdsamp;

public class Wfdbexec {

	private String commandName;
	private static final String fsep=SystemSettings.fsep;
	private static final String osArch= SystemSettings.getosArch();
	private static final String osName=SystemSettings.getOsName();
	protected static final String WFDB_JAVA_HOME=SystemSettings.getWFDB_JAVA_HOME();
	private String WFDB_PATH=null;
	private String WFDBCAL=null;
	private List<String> commandInput;
	protected static Map<String,String> env;
	protected static File EXECUTING_DIR=null;
	protected String[] arguments;
	private int DoubleArrayListCapacity=0;
	private int FloatArrayListCapacity=0;
	private int ShortArrayListCapacity=0;
	private int LongArrayListCapacity=0;
	private static Logger logger =
			Logger.getLogger(Wfdbexec.class.getName());
	private String commandDir;
	private long initialWaitTime;
	private String WFDB_NATIVE_BIN;
	private String LD_PATH;
	public static boolean customArchFlag=false;
	
	public Wfdbexec(String commandName, String commandDir,boolean customArchFlag){
		logger.finest("\n\t***Setting exec commandName to: " + commandDir + commandName);
		this.commandName=commandName;
		this.commandDir=commandDir;
		Wfdbexec.customArchFlag=customArchFlag;
		setWFDB_NATIVE_BIN(SystemSettings.getWFDB_NATIVE_BIN(customArchFlag));
		LD_PATH=SystemSettings.getLD_PATH(customArchFlag);
	}

	public Wfdbexec(String commandName,boolean customArchFlag){
		this(commandName,SystemSettings.getWFDB_NATIVE_BIN(customArchFlag)+"bin" + fsep,customArchFlag);
	}

	public void setArguments(String[] args){
		arguments=args;
	}

	public void setWFDB_PATH(String str){
		//According to https://www.physionet.org/physiotools/wpg/wpg_14.htm#WFDB-path-syntax
		//use white space as best option for all the operating systems
		logger.finest("\n\t***Setting WFDB to: " + str);
		WFDB_PATH=str;
	}
	public void setWFDBCAL(String str){
		logger.finest("\n\t***Setting WFDBCAL to: " + str);
		WFDBCAL=str;
	}
	protected void setExecName(String execName) {
		commandName = execName;
	}

	public void setInitialWaitTime(long tm){
		initialWaitTime=tm;
	}

	public void setWFDB_NATIVE_BIN(String str){
		WFDB_NATIVE_BIN=str;
	}
	
	public void setCustomArchFlag(boolean flag){
		this.customArchFlag=flag;
	}

	public void setExecutingDir(File dir){
		logger.finer("\n\t***Setting EXECUTING_DIR: " 
				+ dir);
		EXECUTING_DIR=dir;
	}

	private void gen_exec_arguments() {
		commandInput = new ArrayList<String>();
		commandInput.add(commandDir + commandName);
		logger.finest("\n\t***commandInput.add = " + commandDir + commandName);
		if(arguments != null){
			for(String i: arguments)
				commandInput.add(i);
		}
	}

	public synchronized ArrayList<String> execToStringList() throws Exception {
		gen_exec_arguments();
		ArrayList<String> results= new ArrayList<String>();
		ProcessBuilder launcher = setLauncher();
		ErrorReader er = null;
		logger.fine("\n\t***Executing Launcher with commandInput : " + "\t" + commandInput);
		String line = null;
		try {
			logger.finer("\n\t***Starting exec process...");
			Process p = launcher.start();
			logger.finer("\n\t***Creating read buffer and waiting for exec process...");
			BufferedReader output = new BufferedReader(new InputStreamReader(
					p.getInputStream(),"US-ASCII"));

			er = new ErrorReader(p.getErrorStream(), logger);
			er.start();

			//Wait for the initial stream in case process is slow
			logger.finest("\n\t***Waiting for data stream from launcher...");
			long thisTime=System.currentTimeMillis();
			long waitTime=thisTime;
			while (!output.ready()){
				if((waitTime-thisTime)> initialWaitTime){
					logger.finest("Process data stream wait time exceeded ("
							+ initialWaitTime + "  milliseconds )");
					logger.finest("\n\t***Could not get data stream, exiting...");
					break;
				}else {
					try {
						Thread.sleep(100);
					} catch(InterruptedException ex) {
						Thread.currentThread().interrupt();
					}
					waitTime=System.currentTimeMillis();
				}
			}
			if(output.ready()){
				logger.finest("\n\t***A was stream initialized, checking if data or err...");
			}

			while ((line = output.readLine()) != null){
				logger.finest("\n\t***Reading output: \n" + line);
				results.add(line);
			}
		} catch (Exception e) {
			System.err.println("error executing: " +
					commandName);
			e.printStackTrace();
			return null;
		} finally {
			if (er != null) {
				er.join();
			}
		}
		return results;
	}


	public synchronized ArrayList<String> execWithStandardInput(String[] inputData) throws Exception {

		gen_exec_arguments();
		ProcessBuilder launcher = setLauncher();
		launcher.redirectErrorStream(true);
		Process process= null;
		int exitStatus = 1; 
		ArrayList<String> results=null;
		try {
			process = launcher.start();
			if (process != null) {
				OutputReader or= new OutputReader(process.getInputStream()) ;
				InputWriter iw= new	InputWriter(process.getOutputStream(), inputData);
				iw.start();	
				or.start();
				iw.join();
				or.join();
				results=or.getResults();
			}
			exitStatus=process.waitFor();
		} catch (IOException e) {
			System.err.println("Either couldn't read from the template file or couldn't write to the OutputStream.");
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		process.destroy();
		if(exitStatus != 0){
			System.err.println("Process exited with errors!! Error code = "
					+exitStatus);
			for(String tmp : results)
				System.err.println(tmp);
		}
		return results;
	}

	public synchronized ArrayList<String> execWithStandardInput(byte[] inputData) throws Exception {

		gen_exec_arguments();
		ProcessBuilder launcher = setLauncher();
		launcher.redirectErrorStream(true);
		Process process= null;
		int exitStatus = 1; 
		ArrayList<String> results=null;
		try {
			process = launcher.start();
			if (process != null) {
				OutputReader or= new OutputReader(process.getInputStream()) ;
				InputWriter iw= new	InputWriter(process.getOutputStream(), inputData);
				iw.start();	
				or.start();
				iw.join();
				or.join();
				results=or.getResults();
			}
			exitStatus=process.waitFor();
		} catch (IOException e) {
			System.err.println("Either couldn't read from the template file or couldn't write to the OutputStream.");
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		process.destroy();
		if(exitStatus != 0){
			System.err.println("Process exited with errors!! Error code = "
					+exitStatus);
			for(String tmp : results)
				System.err.println(tmp);
		}
		return results;
	}
	
	
	public synchronized ArrayList<String> execWithStandardInput(double[][] inputData) throws Exception {

		String[] stringArr=new String[inputData.length];
		for(int i=0;i<inputData.length;i++)
			stringArr[i]=Double.toString(inputData[i][0]);
		return execWithStandardInput(stringArr);

	}


	public synchronized ArrayList<String> execToStringList(String[] args) throws Exception {
		setArguments(args);   
		return execToStringList();
	}


    
	public double[][] execToDoubleArray(String[] args) throws Exception {
		setArguments(args);   
		gen_exec_arguments();

		ArrayList<Double[]>  results= new ArrayList<Double[]>();
		if(DoubleArrayListCapacity>0){
			//Set capacity to ensure more efficiency
			results.ensureCapacity(DoubleArrayListCapacity);
		}
		double[][] data=null;
		int isTime=-1;//Index in case one of the columns is time as string

		ProcessBuilder launcher = null;
		ErrorReader er = null;
		logger.finest("\n\t***Setting launcher in exectToDoubleArray");
		try {
			launcher = setLauncher();
			logger.finest("\n\t***Launcher created sucessfully in exectToDoubleArray");
		} catch (Exception e1) {
			System.err.println("***Error in setting the system launcher:" + e1.toString());
			e1.printStackTrace();
		}
		try {
			logger.finest("\n\t***Starting launcher in exectToDoubleArray");
			Process p = launcher.start();
			BufferedReader output = new BufferedReader(new InputStreamReader(
					p.getInputStream(),"US-ASCII"));
			String line;
			String[] tmpStr=null;
			Double[] tmpArr=null;
			char[] tmpCharArr=null;
			int colInd;
			int dataCheck=0;

			er = new ErrorReader(p.getErrorStream(), logger);
			er.start();
			
			//Wait for the initial stream in case process is slow
			logger.finest("\n\t***Waiting for data stream from launcher...");
			long thisTime=System.currentTimeMillis();
			long waitTime=thisTime;

			while (!output.ready()){
				if((waitTime-thisTime)> initialWaitTime){
					logger.finest("Process data stream wait time exceeded ("
							+ initialWaitTime + "  milliseconds )");
					logger.finest("\n\t***Could not get data stream, exiting...");
					break;
				}else {
					try {
						Thread.sleep(100);
					} catch(InterruptedException ex) {
						Thread.currentThread().interrupt();
					}
					waitTime=System.currentTimeMillis();
				}
			}
			if(output.ready()){
				logger.finest("\n\t***Streamed communication received, checking if error or data...");
			}

			/* The number of columns for the output array */
			int N=1;
			
			/* Just get the second column. We only care about annotation samples */
			if (commandName.equals("rdann")){
			    while ((line = output.readLine()) != null){
				tmpStr=line.trim().split("\\s+");
				tmpArr=new Double[1];
				tmpArr[0] = Double.valueOf(tmpStr[1]);
				
				if(results.isEmpty() && dataCheck==tmpStr.length){
				    System.err.println("Error: Cannot convert to double: ");
				    System.err.println(line);
				    throw new NumberFormatException("Cannot convert");
				}else {
				    results.add(tmpArr);
				}
			    }
			}
			/* For non rdann function calls */
			else{
			    while ((line = output.readLine()) != null){
				tmpStr=line.trim().split("\\s+");
				tmpArr=new Double[tmpStr.length];
				//loop through columns
				for(colInd=0;colInd<tmpStr.length;colInd++){
				    try{    
					tmpArr[colInd]= Double.valueOf(tmpStr[colInd]);
				    }catch (NumberFormatException e){
					//Deal with cases that are not numbers 
					//but in an expected format
					if(tmpStr[colInd].equals("-")){
					    //Dealing with NaN , so we need to convert 
					    //WFDB Syntax "-" to Java's Double NaN
					    tmpArr[colInd]=Double.NaN;	
					}else if((tmpStr[colInd].contains(":"))){
					    //This column is likely a time column
					    //for now, set values to NaN and remove column
					    tmpArr[colInd]=Double.NaN;
					    if(isTime<0){
						isTime=colInd;
					    }
					    dataCheck++;
					}else {
					    //Attempt to convert single characters to integers
					    try{
						tmpCharArr=tmpStr[colInd].toCharArray();
						tmpArr[colInd]= (double) tmpCharArr[0];
						dataCheck++;
					    }catch(Exception e2) {
						System.err.println("Could not convert to double: " + line);
						throw new Exception(e2.toString());
					    }
					}
				    }
				}

				if(results.isEmpty() && dataCheck==tmpStr.length){
				    System.err.println("Error: Cannot convert to double: ");
				    System.err.println(line);
				    throw new NumberFormatException("Cannot convert");
				}else {
				    results.add(tmpArr);
				}
			    }
			    /* Basing ncolumns on the last row of stream. */
			    N=tmpStr.length;
			    if(isTime>-1){
				N--;
			    }
			}

			//Wait to for exit value
			int exitValue = p.waitFor();
			if(exitValue != 0){
				System.err.println("Command exited with non-zero status!!");
			}
			//Convert data to Double Array
			
			//TODO: find a way to use .toArray in case of column deletion
			//data=new double[results.size()][N];
			//data=results.toArray(data); this should replace the loops below

			data=new double[results.size()][N];
			int index=0;
			if(isTime>-1) {
				for(int i=0;i<results.size();i++){
					Double[] tmpData=new Double[tmpStr.length];
					tmpData=results.get(i);
					for(int k=0;k<N;k++){				
						if(isTime > -1 && k != isTime)
							index =  (k>isTime) ? (k-1) :k;
							data[i][index]=tmpData[k];
					}
				}
			} else { //Optimized for case where there is no 
				//column deletion
				for(int i=0;i<results.size();i++){
					Double[] tmpData=new Double[tmpStr.length];
					tmpData=results.get(i);
					for(int k=0;k<N;k++){				
						data[i][k]=tmpData[k];
					}
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		} finally {
			if (er != null) {
				er.join();
			}
		}
		return data;
	}
    
	
	public ArrayList<Double> execToDoubleList(String[] args) throws Exception {
		setArguments(args);   
		gen_exec_arguments();

		ArrayList<Double>  results= new ArrayList<Double>();
		if(DoubleArrayListCapacity>0){
			//Set capacity to ensure more efficiency
			results.ensureCapacity(DoubleArrayListCapacity);
		}
		int isTime=-1;//Index in case one of the columns is time as string

		ProcessBuilder launcher = null;
		ErrorReader er = null;
		logger.finest("\n\t***Setting launcher in exectToDoubleArray");
		try {
			launcher = setLauncher();
			logger.finest("\n\t***Launcher created sucessfully in exectToDoubleArray");
		} catch (Exception e1) {
			System.err.println("***Error in setting the system launcher:" + e1.toString());
			e1.printStackTrace();
		}
		try {
			logger.finest("\n\t***Starting launcher in exectToDoubleArray");
			Process p = launcher.start();
			BufferedReader output = new BufferedReader(new InputStreamReader(
					p.getInputStream()));
			String line;
			String[] tmpStr=null;
			char[] tmpCharArr=null;
			int colInd;

			er = new ErrorReader(p.getErrorStream(), logger);
			er.start();

			//Wait for the initial stream in case process is slow
			logger.finest("\n\t***Waiting for data stream from launcher...");
			long thisTime=System.currentTimeMillis();
			long waitTime=thisTime;

			while (!output.ready()){
				if((waitTime-thisTime)> initialWaitTime){
					logger.finest("Process data stream wait time exceeded ("
							+ initialWaitTime + "  milliseconds )");
					logger.finest("\n\t***Could not get data stream, exiting...");
					break;
				}else {
					try {
						Thread.sleep(100);
					} catch(InterruptedException ex) {
						Thread.currentThread().interrupt();
					}
					waitTime=System.currentTimeMillis();
				}
			}
			if(output.ready()){
				logger.finest("\n\t***Streamed communication received, checking if error or data...");
			}
			while ((line = output.readLine()) != null){
				tmpStr=line.trim().split("\\s+");
				//loop through columns
				for(colInd=0;colInd<tmpStr.length;colInd++){
					try{    
						results.add(Double.valueOf(tmpStr[colInd]));
					}catch (NumberFormatException e){
						//Deal with cases that are not numbers 
						//but in an expected format
						if(tmpStr[colInd].equals("-")){
							//Dealing with NaN , so we need to convert 
							//WFDB Syntax "-" to Java's Double NaN
							results.add(Double.NaN);	
						}else if((tmpStr[colInd].contains(":"))){
							//This column is likely a time column
							//for now, set values to NaN and remove column
							results.add(Double.NaN);
							if(isTime<0){
								isTime=colInd;
							}
						}else {
							//Attempt to convert single characters to integers
							try{
								tmpCharArr=tmpStr[colInd].toCharArray();
								results.add((double) tmpCharArr[0]);
							}catch(Exception e2) {
								System.err.println("Could not convert to double: " + line);
								throw new Exception(e2.toString());
							}
						}
					}
				}
			}
			//Wait to for exit value
			int exitValue = p.waitFor();
			if(exitValue != 0){
				System.err.println("Command exited with non-zero status!!");
			}
					} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		} finally {
			if (er != null) {
				er.join();
			}
		}
		return results;
	}


	public float[][] execToFloatArray(String[] args) throws Exception {
		setArguments(args);   
		gen_exec_arguments();

		ArrayList<Float[]>  results= new ArrayList<Float[]>();
		if(FloatArrayListCapacity>0){
			//Set capacity to ensure more efficiency
			results.ensureCapacity(FloatArrayListCapacity);
		}
		float[][] data=null;
		int isTime=-1;//Index in case one of the columns is time as string

		ProcessBuilder launcher = null;
		ErrorReader er = null;
		logger.finest("\n\t***Setting launcher in exectToFloatArray");
		try {
			launcher = setLauncher();
			logger.finest("\n\t***Launcher created sucessfully in exectToFloatArray");
		} catch (Exception e1) {
			System.err.println("***Error in setting the system launcher:" + e1.toString());
			e1.printStackTrace();
		}
		try {
			logger.finest("\n\t***Starting launcher in exectToFloatArray");
			Process p = launcher.start();
			BufferedReader output = new BufferedReader(new InputStreamReader(
					p.getInputStream()));
			String line;
			String[] tmpStr=null;
			Float[] tmpArr=null;
			char[] tmpCharArr=null;
			int colInd;
			int dataCheck=0;

			er = new ErrorReader(p.getErrorStream(), logger);
			er.start();

			//Wait for the initial stream in case process is slow
			logger.finest("\n\t***Waiting for data stream from launcher...");
			long thisTime=System.currentTimeMillis();
			long waitTime=thisTime;

			while (!output.ready()){
				if((waitTime-thisTime)> initialWaitTime){
					logger.finest("Process data stream wait time exceeded ("
							+ initialWaitTime + "  milliseconds )");
					logger.finest("\n\t***Could not get data stream, exiting...");
					break;
				}else {
					try {
						Thread.sleep(100);
					} catch(InterruptedException ex) {
						Thread.currentThread().interrupt();
					}
					waitTime=System.currentTimeMillis();
				}
			}
			if(output.ready()){
				logger.finest("\n\t***Streamed communication received, checking if error or data...");
			}
			while ((line = output.readLine()) != null){
				tmpStr=line.trim().split("\\s+");
				tmpArr=new Float[tmpStr.length];
				//loop through columns
				for(colInd=0;colInd<tmpStr.length;colInd++){
					try{    
						tmpArr[colInd]= Float.valueOf(tmpStr[colInd]);
					}catch (NumberFormatException e){
						//Deal with cases that are not numbers 
						//but in an expected format
						if(tmpStr[colInd].equals("-")){
							//Dealing with NaN , so we need to convert 
							//WFDB Syntax "-" to Java's Float NaN
							tmpArr[colInd]=Float.NaN;	
						}else if((tmpStr[colInd].contains(":"))){
							//This column is likely a time column
							//for now, set values to NaN and remove column
							tmpArr[colInd]=Float.NaN;
							if(isTime<0){
								isTime=colInd;
							}
							dataCheck++;
						}else {
							//Attempt to convert single characters to integers
							try{
								tmpCharArr=tmpStr[colInd].toCharArray();
								tmpArr[colInd]= (float) tmpCharArr[0];
								dataCheck++;
							}catch(Exception e2) {
								System.err.println("Could not convert to double: " + line);
								throw new Exception(e2.toString());
							}
						}
					}
				}

				if(results.isEmpty() && dataCheck==tmpStr.length){
					System.err.println("Error: Cannot convert to double: ");
					System.err.println(line);
					throw new NumberFormatException("Cannot convert");
				}else {
					results.add(tmpArr);
				}
			}

			//Wait to for exit value
			int exitValue = p.waitFor();
			if(exitValue != 0){
				System.err.println("Command exited with non-zero status!!");
			}
			//Convert data to Float Array
			int N=tmpStr.length;
			if(isTime>-1){
				N--;
			}
			//TODO: find a way to use .toArray in case of column deletion
			//data=new double[results.size()][N];
			//data=results.toArray(data); this should replace the loops below

			data=new float[results.size()][N];
			int index=0;
			if(isTime>-1) {
				for(int i=0;i<results.size();i++){
					Float[] tmpData=new Float[tmpStr.length];
					tmpData=results.get(i);
					for(int k=0;k<N;k++){				
						if(isTime > -1 && k != isTime)
							index =  (k>isTime) ? (k-1) :k;
							data[i][index]=tmpData[k];
					}
				}
			} else { //Optimized for case where there is no 
				//column deletion
				for(int i=0;i<results.size();i++){
					Float[] tmpData=new Float[tmpStr.length];
					tmpData=results.get(i);
					for(int k=0;k<N;k++){				
						data[i][k]=tmpData[k];
					}
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		} finally {
			if (er != null) {
				er.join();
			}
		}
		return data;
	}

	public long[][] execToLongArray(String[] args) throws Exception {
		setArguments(args);   
		gen_exec_arguments();

		ArrayList<Long[]>  results= new ArrayList<Long[]>();
		if(LongArrayListCapacity>0){
			//Set capacity to ensure more efficiency
			results.ensureCapacity(LongArrayListCapacity);
		}
		long[][] data=null;
		int isTime=-1;//Index in case one of the columns is time as string

		ProcessBuilder launcher = null;
		ErrorReader er = null;
		logger.finest("\n\t***Setting launcher in exectToLongArray");
		try {
			launcher = setLauncher();
			logger.finest("\n\t***Launcher created sucessfully in exectToLongArray");
		} catch (Exception e1) {
			System.err.println("***Error in setting the system launcher:" + e1.toString());
			e1.printStackTrace();
		}
		try {
			logger.finest("\n\t***Starting launcher in exectToLongArray");
			Process p = launcher.start();
			BufferedReader output = new BufferedReader(new InputStreamReader(
					p.getInputStream()));
			String line;
			String[] tmpStr=null;
			Long[] tmpArr=null;
			char[] tmpCharArr=null;
			int colInd;
			int dataCheck=0;

			er = new ErrorReader(p.getErrorStream(), logger);
			er.start();

			//Wait for the initial stream in case process is slow
			logger.finest("\n\t***Waiting for data stream from launcher...");
			long thisTime=System.currentTimeMillis();
			long waitTime=thisTime;

			while (!output.ready()){
				if((waitTime-thisTime)> initialWaitTime){
					logger.finest("Process data stream wait time exceeded ("
							+ initialWaitTime + "  milliseconds )");
					logger.finest("\n\t***Could not get data stream, exiting...");
					break;
				}else {
					try {
						Thread.sleep(100);
					} catch(InterruptedException ex) {
						Thread.currentThread().interrupt();
					}
					waitTime=System.currentTimeMillis();
				}
			}
			if(output.ready()){
				logger.finest("\n\t***Streamed communication received, checking if error or data...");
			}
			while ((line = output.readLine()) != null){
				tmpStr=line.trim().split("\\s+");
				tmpArr=new Long[tmpStr.length];
				//loop through columns
				for(colInd=0;colInd<tmpStr.length;colInd++){
					try{    
						tmpArr[colInd]= Long.valueOf(tmpStr[colInd]);
					}catch (NumberFormatException e){
						//Deal with cases that are not numbers 
						//but in an expected format
						if(tmpStr[colInd].equals("-")){
							//Dealing with NaN , so we need to convert 
							//WFDB Syntax "-" to Java's Long NaN
							tmpArr[colInd]=Long.MIN_VALUE;	
						}else if((tmpStr[colInd].contains(":"))){
							//This column is likely a time column
							//for now, set values to NaN and remove column
							tmpArr[colInd]=Long.MIN_VALUE;
							if(isTime<0){
								isTime=colInd;
							}
							dataCheck++;
						}else {
							//Attempt to convert single characters to integers
							try{
								tmpCharArr=tmpStr[colInd].toCharArray();
								tmpArr[colInd]= (long) tmpCharArr[0];
								dataCheck++;
							}catch(Exception e2) {
								System.err.println("Could not convert to double: " + line);
								throw new Exception(e2.toString());
							}
						}
					}
				}

				if(results.isEmpty() && dataCheck==tmpStr.length){
					System.err.println("Error: Cannot convert to double: ");
					System.err.println(line);
					throw new NumberFormatException("Cannot convert");
				}else {
					results.add(tmpArr);
				}
			}

			//Wait to for exit value
			int exitValue = p.waitFor();
			if(exitValue != 0){
				System.err.println("Command exited with non-zero status!!");
			}
			//Convert data to Long Array
			int N=tmpStr.length;
			if(isTime>-1){
				N--;
			}
			//TODO: find a way to use .toArray in case of column deletion
			//data=new double[results.size()][N];
			//data=results.toArray(data); this should replace the loops below

			data=new long[results.size()][N];
			int index=0;
			if(isTime>-1) {
				for(int i=0;i<results.size();i++){
					Long[] tmpData=new Long[tmpStr.length];
					tmpData=results.get(i);
					for(int k=0;k<N;k++){				
						if(isTime > -1 && k != isTime)
							index =  (k>isTime) ? (k-1) :k;
							data[i][index]=tmpData[k];
					}
				}
			} else { //Optimized for case where there is no 
				//column deletion
				for(int i=0;i<results.size();i++){
					Long[] tmpData=new Long[tmpStr.length];
					tmpData=results.get(i);
					for(int k=0;k<N;k++){				
						data[i][k]=tmpData[k];
					}
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		} finally {
			if (er != null) {
				er.join();
			}
		}
		return data;
	}


	public short[][] execToShortArray(String[] args) throws Exception {
		setArguments(args);   
		gen_exec_arguments();

		ArrayList<Short[]>  results= new ArrayList<Short[]>();
		if(ShortArrayListCapacity>0){
			//Set capacity to ensure more efficiency
			results.ensureCapacity(ShortArrayListCapacity);
		}
		short[][] data=null;
		int isTime=-1;//Index in case one of the columns is time as string

		ProcessBuilder launcher = null;
		ErrorReader er = null;
		logger.finest("\n\t***Setting launcher in exectToShortArray");
		try {
			launcher = setLauncher();
			logger.finest("\n\t***Launcher created sucessfully in exectToShortArray");
		} catch (Exception e1) {
			System.err.println("***Error in setting the system launcher:" + e1.toString());
			e1.printStackTrace();
		}
		try {
			logger.finest("\n\t***Starting launcher in exectToShortArray");
			Process p = launcher.start();
			BufferedReader output = new BufferedReader(new InputStreamReader(
					p.getInputStream()));
			String line;
			String[] tmpStr=null;
			Short[] tmpArr=null;
			char[] tmpCharArr=null;
			int colInd;
			int dataCheck=0;

			er = new ErrorReader(p.getErrorStream(), logger);
			er.start();

			//Wait for the initial stream in case process is slow
			logger.finest("\n\t***Waiting for data stream from launcher...");
			long thisTime=System.currentTimeMillis();
			long waitTime=thisTime;

			while (!output.ready()){
				if((waitTime-thisTime)> initialWaitTime){
					logger.finest("Process data stream wait time exceeded ("
							+ initialWaitTime + "  milliseconds )");
					logger.finest("\n\t***Could not get data stream, exiting...");
					break;
				}else {
					try {
						Thread.sleep(100);
					} catch(InterruptedException ex) {
						Thread.currentThread().interrupt();
					}
					waitTime=System.currentTimeMillis();
				}
			}
			if(output.ready()){
				logger.finest("\n\t***Streamed communication received, checking if error or data...");
			}
			while ((line = output.readLine()) != null){
				tmpStr=line.trim().split("\\s+");
				tmpArr=new Short[tmpStr.length];
				//loop through columns
				for(colInd=0;colInd<tmpStr.length;colInd++){
					try{    
						tmpArr[colInd]= Short.valueOf(tmpStr[colInd]);
					}catch (NumberFormatException e){
						//Deal with cases that are not numbers 
						//but in an expected format
						if(tmpStr[colInd].equals("-")){
							//Dealing with NaN , so we need to convert 
							//WFDB Syntax "-" to Java's Short NaN
							tmpArr[colInd]=Short.MIN_VALUE;	
						}else if((tmpStr[colInd].contains(":"))){
							//This column is likely a time column
							//for now, set values to NaN and remove column
							tmpArr[colInd]=Short.MIN_VALUE;
							if(isTime<0){
								isTime=colInd;
							}
							dataCheck++;
						}else {
							//Attempt to convert single characters to integers
							try{
								tmpCharArr=tmpStr[colInd].toCharArray();
								tmpArr[colInd]= (short) tmpCharArr[0];
								dataCheck++;
							}catch(Exception e2) {
								System.err.println("Could not convert to double: " + line);
								throw new Exception(e2.toString());
							}
						}
					}
				}

				if(results.isEmpty() && dataCheck==tmpStr.length){
					System.err.println("Error: Cannot convert to double: ");
					System.err.println(line);
					throw new NumberFormatException("Cannot convert");
				}else {
					results.add(tmpArr);
				}
			}

			//Wait to for exit value
			int exitValue = p.waitFor();
			if(exitValue != 0){
				System.err.println("Command exited with non-zero status!!");
			}
			//Convert data to Short Array
			int N=tmpStr.length;
			if(isTime>-1){
				N--;
			}
			//TODO: find a way to use .toArray in case of column deletion
			//data=new double[results.size()][N];
			//data=results.toArray(data); this should replace the loops below

			data=new short[results.size()][N];
			int index=0;
			if(isTime>-1) {
				for(int i=0;i<results.size();i++){
					Short[] tmpData=new Short[tmpStr.length];
					tmpData=results.get(i);
					for(int k=0;k<N;k++){				
						if(isTime > -1 && k != isTime)
							index =  (k>isTime) ? (k-1) :k;
							data[i][index]=tmpData[k];
					}
				}
			} else { //Optimized for case where there is no 
				//column deletion
				for(int i=0;i<results.size();i++){
					Short[] tmpData=new Short[tmpStr.length];
					tmpData=results.get(i);
					for(int k=0;k<N;k++){				
						data[i][k]=tmpData[k];
					}
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
		} catch (InterruptedException e) {
			e.printStackTrace();
		} finally {
			if (er != null) {
				er.join();
			}
		}
		return data;
	}

	public void loadCurl(){
		SystemSettings.loadCurl(customArchFlag);
	}
	
	private synchronized ProcessBuilder setLauncher() throws Exception{
		ProcessBuilder launcher = new ProcessBuilder();
		//The error stream should not be redirected to the same output stream
		//because it can affect the parser during warnings
		launcher.redirectErrorStream(false);
		env = launcher.environment();
		//Set Java library Path
		env.put("java.library.path",LD_PATH);
		
		//Add library path to environment
		if(osName.contains("mac")){
			env.put("DYLD_LIBRARY_PATH",LD_PATH);
			logger.finer("\n\t***setting: DYLD_LIBRARY_PATH: " + LD_PATH);
			env.put("PATH",LD_PATH);
			logger.finer("\n\t***setting: MacOs PATH: " + LD_PATH);
		}else if(osName.contains("windows")){
			env.put("Path",LD_PATH);
			logger.finer("\n\t***setting: Windows Path: " + LD_PATH);
		}else if(osName.contains("linux")){
			env.put("LD_LIBRARY_PATH",LD_PATH);
			logger.finer("\n\t***setting: Linux LD_LIBRARY_PATH: " + LD_PATH);
		}else{
			//assumes Linux
			env.put("LD_LIBRARY_PATH",LD_PATH);
			logger.finer("\n\tsetting: ***Defaulting to Linux LD_LIBRARY_PATH: " + LD_PATH);
		}
		env.put("WFDBNOSORT","1");
		if(WFDB_PATH != null){
			env.put("WFDB",WFDB_PATH);
			logger.finer("\n\tsetting: **WFDB PATH: " + WFDB_PATH);
		}
		if(WFDBCAL != null){ 
			env.put("WFDBCAL",WFDBCAL);
		}

		launcher.environment().put("WFDBNOSORT","1");
		logger.finest("\n\t***Setting executing process with command and arguments: " + commandInput);
		launcher.command(commandInput);
		if(EXECUTING_DIR != null){
			launcher.directory(EXECUTING_DIR);
		}

		//Set process initial wait time for data streams
		setInitialWaitTime(1000);
		return launcher;
	}

	//Private Methods
	public List<String> getEnvironment(){
		ArrayList<String> variables= new ArrayList<String>();
		variables.add("WFDB_JAVA_HOME=" + WFDB_JAVA_HOME);
		logger.finer("\n\t***WFDB_JAVA_HOME: " + WFDB_JAVA_HOME);

		variables.add("WFDB_NATIVE_BIN=" + WFDB_NATIVE_BIN);
		logger.finer("\n\t***WFDB_NATIVE_BIN: " + WFDB_NATIVE_BIN);
		variables.add("EXECUTING_DIR="+ EXECUTING_DIR);
		logger.finer("\n\t***Exec dir: " + EXECUTING_DIR);
		variables.add("osName=" + osName);
		logger.finer("\n\t***OS: " + osName);
		variables.add("fullOsName=" + System.getProperty("os.name"));
		logger.finer("\n\t***fullOsName: " + System.getProperty("os.name"));
		variables.add("osArch=" + osArch);
		logger.finer("\n\t***OS Arch: " + osArch);
		variables.add("customArchFlag=" + customArchFlag);
		logger.finer("\n\t***customArchFlag: " + customArchFlag);
		variables.add("OS Version=" + System.getProperty("os.version"));
		logger.finer("\n\t***OS Version: " + System.getProperty("os.version"));
		variables.add("JVM Version=" + System.getProperty("java.version"));
		logger.finer("\n\t***JVM Version: " + System.getProperty("java.version"));
		return variables;
	}

	public void printEnvironment(){
		for(String tmp : env.keySet()){
			if(tmp == null){
				System.out.println("Environment is null");
			}else{
				System.out.println(tmp + " = " + env.get(tmp));
			}
		}
	}

	public void setDoubleArrayListCapacity(int capacity){
		DoubleArrayListCapacity=capacity;
	}

	public void setFloatArrayListCapacity(int capacity){
		FloatArrayListCapacity=capacity;
	}

	public void setLongArrayListCapacity(int capacity){
		LongArrayListCapacity=capacity;
	}

	public void setShortArrayListCapacity(int capacity){
		ShortArrayListCapacity=capacity;
	}

	public void setLogLevel(int level){
		//Include this method to allow for debugging within MATLAB instances
		Level debugLevel;
		switch (level) {
		case 0:
			debugLevel=Level.OFF;break;
		case 1:
			debugLevel=Level.SEVERE;break;
		case 2:
			debugLevel=Level.WARNING;break;
		case 3: 
			debugLevel=Level.INFO;break;
		case 4:
			debugLevel=Level.FINEST;break;
		case 5:
			debugLevel=Level.ALL;break;
		default :
			debugLevel=Level.OFF;break;
		}

		Handler[] handlers =
				Logger.getLogger( "" ).getHandlers();
		for ( int index = 0; index < handlers.length; index++ ) {
			handlers[index].setLevel( debugLevel );
		}

		Logger.getLogger("org.physionet").setLevel(debugLevel);
	}
	
	public static void main(String[] args) throws Exception {

		Level debugLevel = Level.FINEST;//use for debugging Level.FINEST;
		if(debugLevel != null){
			Handler[] handlers =
					Logger.getLogger( "" ).getHandlers();
			for ( int index = 0; index < handlers.length; index++ ) {
				handlers[index].setLevel( debugLevel );
			}
			Logger.getLogger("org.physionet.wfdb.Wfdbexec").setLevel(debugLevel);
			Logger.getLogger("org.physionet.wfdb.SystemSettings").setLevel(debugLevel);
		}

		Wfdbexec exec = new Wfdbexec(args[0],Boolean.getBoolean(args[1]));
		double[][] data = exec.execToDoubleArray(Arrays.copyOfRange(args,1,args.length));
		for(int row=0;row<data.length;row++){
			for(int col=0;col<data[0].length;col++){
				System.out.print(data[row][col] +" ");
			}
			System.out.println("");
		}

	}

} 
