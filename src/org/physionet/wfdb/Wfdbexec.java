/* ===========================================================
 * WFDB Java : Interface to WFDB Applications.
 *              
 * ===========================================================
 *
 * (C) Copyright 2012, by Ikaro Silva
 *
 * Project Info:
 *    Code: http://code.google.com/p/wfdb-java/
 *    WFDB: http://www.physionet.org/physiotools/wfdb.shtml
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

public class Wfdbexec {

	private String commandName;
	private static final String fileSeparator=SystemSettings.getFileSeparator();
	private static final String osArch= SystemSettings.getosArch();
	private static final String osName=SystemSettings.getOsName();
	protected static final String WFDB_JAVA_HOME=SystemSettings.getWFDB_JAVA_HOME();
	private String WFDB_PATH;
	private String WFDBCAL;
	private List<String> commandInput;
	protected static Map<String,String> env;
	protected static File EXECUTING_DIR=null;
	protected String[] arguments;
	private int DoubleArrayListCapacity=0;
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
		WFDB_NATIVE_BIN=SystemSettings.getWFDB_NATIVE_BIN(customArchFlag);
		LD_PATH=SystemSettings.getLD_PATH(customArchFlag);
		logger.finest("\n\t***Loading System libraries...");
		SystemSettings.getLD_PATH(customArchFlag);
		//Use white spaces for compatibility with all the operating systems
		WFDB_PATH=SystemSettings.getDefaultWFDBPath(); 
		WFDBCAL=SystemSettings.getDefaultWFDBCal(); 
	}

	public Wfdbexec(String commandName,boolean customArchFlag){
		this(commandName,SystemSettings.getWFDB_NATIVE_BIN(customArchFlag)+"bin" + fileSeparator,customArchFlag);
	}

	public void setArguments(String[] args){
		arguments=args;
	}

	public void setWFDB_PATH(String str){
		//Acording to http://www.physionet.org/physiotools/wpg/wpg_14.htm#WFDB-path-syntax
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
		//TODO: For the RDSAMP case:
		//ensure array capacity when user submits N0 and N
		//or (default) by querying the signal size
		//for now, have this happens at the MATLAB wrapper level
	}

	public synchronized ArrayList<String> execToStringList() throws Exception {
		gen_exec_arguments();
		ArrayList<String> results= new ArrayList<String>();
		ProcessBuilder launcher = setLauncher();
		logger.fine("\n\t***Executing Launcher with commandInput : " + "\t" + commandInput);
		String line = null;
		try {
			logger.finer("\n\t***Starting exec process...");
			Process p = launcher.start();
			logger.finer("\n\t***Creating read buffer and waiting for exec process...");
			BufferedReader output = new BufferedReader(new InputStreamReader(
					p.getInputStream()));
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
						logger.finest("Waited " + (waitTime-thisTime) +
								" ms for data stream (max waiting time= " +
								initialWaitTime + "ms ) ...");
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
			Double[] tmpArr=null;
			char[] tmpCharArr=null;
			int colInd;
			int dataCheck=0;

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
						logger.finest("Waited " + (waitTime-thisTime) +
								" ms for data stream (max waiting time= " +
								initialWaitTime + "ms ) ...");
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

			//Wait to for exit value
			int exitValue = p.waitFor();
			if(exitValue != 0){
				System.err.println("Command exited with non-zero status!!");
			}
			//Convert data to Double Array
			int N=tmpStr.length;
			if(isTime>-1){
				N--;
			}
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
		}   
		return data;
	}

	private synchronized ProcessBuilder setLauncher() throws Exception{
		ProcessBuilder launcher = new ProcessBuilder();
		launcher.redirectErrorStream(true);
		env = launcher.environment();
		//Add library path to environment
 		if(osName.contains("macosx")){
 			env.put("DYLD_LIBRARY_PATH",LD_PATH);
			logger.finer("\n\t***setting: DYLD_LIBRARY_PATH: " + LD_PATH);
			env.put("PATH",LD_PATH);
			logger.finer("\n\t***setting: PATH: " + LD_PATH);
		}else if(osName.contains("windows")){
			env.put("Path",LD_PATH);
			logger.finer("\n\t***setting: Path: " + LD_PATH);
		}else{
			//assumes Linux
			env.put("LD_LIBRARY_PATH",LD_PATH);
			logger.finer("\n\tsetting: ***LD_LIBRARY_PATH: " + LD_PATH);
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
		variables.add("WFDB_JAVA_HOME= " + WFDB_JAVA_HOME);
		logger.finer("\n\t***WFDB_JAVA_HOME: " + WFDB_JAVA_HOME);

		variables.add("WFDB_NATIVE_BIN= " + WFDB_NATIVE_BIN);
		logger.finer("\n\t***WFDB_NATIVE_BINr: " + WFDB_NATIVE_BIN);
		variables.add("EXECUTING_DIR= "+ EXECUTING_DIR);
		logger.finer("\n\t***Exec dir: " + EXECUTING_DIR);
		variables.add("osName= " + osName);
		logger.finer("\n\t***OS: " + osName);
		variables.add("fullOsName= " + System.getProperty("os.name"));
		logger.finer("\n\t***fullOsName: " + System.getProperty("os.name"));
		variables.add("osArch= " + osArch);
		logger.finer("\n\t***OS Arch: " + osArch);
		variables.add("customArchFlag= " + this.customArchFlag);
		logger.finer("\n\t***customArchFlag: " + this.customArchFlag);
		variables.add("OS Version= " + System.getProperty("os.version"));
		logger.finer("\n\t***OS Version: " + System.getProperty("os.version"));
		variables.add("JVM Version= " + System.getProperty("java.version"));
		logger.finer("\n\t***JVM Version: " + System.getProperty("java.version"));
		return variables;
	}

	public void printEnvironment(){
		for(String tmp : env.keySet()){
			if(tmp == null){
				System.out.println("Environment is null");
			}else{
				System.out.println(tmp + " = " + env.get(tmp));
				System.out.println("Loaded libraries: ");
				System.out.println(SystemSettings.getLoadedLibraries(this));
			}
		}
	}

	public void setDoubleArrayListCapacity(int capacity){
		DoubleArrayListCapacity=capacity;
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
