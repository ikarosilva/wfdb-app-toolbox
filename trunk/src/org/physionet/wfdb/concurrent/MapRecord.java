/*
 * ===========================================================
 * MapRecord 2013
 *              
 * ===========================================================
 *
 * (C) Copleft 2013, by Ikaro Silva
 *
 * Project Info:
 *    Code: http://code.google.com/p/wfdb-app-toolbox/
 *    
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
 * Author:  Ikaro Silva,
 * 
 *  
 * Last Modified:	 July 3, 2013
 * 
 * Changes
 * -------
 * Check: http://code.google.com/p/wfdb-java/list
 * 
 *
 */

package org.physionet.wfdb.concurrent;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.physionet.wfdb.Wfdbexec;
import org.physionet.wfdb.physiobank.PhysioNetDB;
import org.physionet.wfdb.physiobank.PhysioNetRecord;

public class  MapRecord implements Callable<Double>{
	private static final int MAX_THREADS=Runtime.getRuntime().availableProcessors();
	private final int N;		//Total number of records
	private final BlockingQueue<String> tasks;
	private final HashMap<String,Integer> index;
	private double[][] results;
	private static String commandName;
	private final String startTime;
	private final String endTime;
	private static final String UNSPECIFIED_SAMPLE="0"; //In this should read entire wfdb record (for both start and end samples)


	public MapRecord(ArrayList<String> recordList,String commandName) throws InterruptedException{
		this(recordList,commandName,UNSPECIFIED_SAMPLE,UNSPECIFIED_SAMPLE);
	}

	public MapRecord(ArrayList<String> recordList,String commandName,
			String startTime,String endTime) throws InterruptedException{

		//Set task queue 
		N= recordList.size();
		results=new double[N][];
		tasks=new ArrayBlockingQueue<String>(N);
		index=new HashMap<String,Integer>();
		Integer ind=0;
		MapRecord.commandName=commandName;
		this.startTime=startTime;
		this.endTime=endTime;
		for(String rec : recordList){
			tasks.put(rec);
			index.put(rec,ind);
			ind++;
		}
	}

	public MapRecord(String dataBase,String commandName) 
			throws InterruptedException{
		this(dataBase,commandName,UNSPECIFIED_SAMPLE,UNSPECIFIED_SAMPLE); //Start from beginning of the record and leave end unspecified
	}


	public MapRecord(String dataBase,String commandName,
			String startTime,String endTime) throws InterruptedException{
		//Initialize record list
		PhysioNetDB db = new PhysioNetDB(dataBase);
		db.setDBRecordList();
		ArrayList<PhysioNetRecord> recordList = db.getDBRecordList();

		//Set task queue 
		N= recordList.size();
		results=new double[N][];
		tasks=new ArrayBlockingQueue<String>(N);
		index=new HashMap<String,Integer>();
		Integer ind=0;
		MapRecord.commandName=commandName;
		this.startTime=startTime;
		this.endTime=endTime;
		for(PhysioNetRecord rec : recordList){
			tasks.put(rec.getRecordName());
			index.put(rec.getRecordName(),ind);
			ind++;
		}
	}

	public double[][] getResults(){
		return results;
	}

	public HashMap<String,Integer> getIndexMap(){
		return index;
	}

	public Double call(){
		double fail=0;
		String taskInd;
		long id=Thread.currentThread().getId();
		while ((taskInd = tasks.poll()) != null ){ 
			//System.out.println("Thread [" + id + "]: Processing: " + taskInd);
			results[index.get(taskInd)]=compute(taskInd).clone();
		}
		return fail;
	}


	public double[] compute(String record){

		Wfdbexec rdsamp=new Wfdbexec("rdsamp");
		Wfdbexec exec=new Wfdbexec(commandName,"");

		String[] arguments={"-r",record,"-f",startTime,"-t",endTime,"-P"};

		//Execute command
		double[][] inputData=null;
		ArrayList<String> y;
		double[] out = null;
		try {
			inputData=rdsamp.execToDoubleArray(arguments);
			y=exec.execWithStandardInput(inputData);
			out=new double[y.size()];
			for(int n=0;n<y.size();n++)
				out[n]=Double.valueOf(y.get(n));
		} catch (Exception e) {
			e.printStackTrace();
		}
		return out;
	}


	public static void main(String[] args){

		double[][] results=start(args);
		String[] recList=getRecordList(args);
		for(int i=0;i<results.length;i++){
			System.out.println(recList[i]+  " :\t");
			for(int k=0;k<results[i].length;k++)
				System.out.print(results[i][k] + " ");
			System.out.println("");
		}
	}

	public static String[] getRecordList(String[] args){


		if(args.length<3){
			System.out.println("Usage: MapRecord databaseName commandName commandDir nThreads stopTime startTime");
			System.out.println("Example 1: MapRecord aami-ec13 dfa /home/ikaro/workspace/wfdb-app-toolbox/mcode/example/");
			System.out.println("Example 2: MapRecord aami-ec13 dfa /home/ikaro/workspace/wfdb-app-toolbox/mcode/example/ 3");
		}
		MapRecord map=null;
		String database=args[0];
		String commandName=args[1];

		try {
			map = new MapRecord(database,commandName);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		HashMap<String, Integer> indexMap = map.getIndexMap();
		String[] recList=new String[indexMap.size()];
		indexMap.keySet().toArray(recList);

		//System.out.println("!!Done: Processed records: " + results.length);
		return recList;
	}

	public static double[][] start(String[] args){

		double[][] results = null;
		
		if(args.length<3){
			System.out.println("Usage: MapRecord databaseName fullpathTocommandName nThreads stopTime startTime");
			System.out.println("Example 1: MapRecord aami-ec13  /home/ikaro/workspace/wfdb-app-toolbox/mcode/example/dfa");
			System.out.println("Example 2: MapRecord aami-ec13 /home/ikaro/workspace/wfdb-app-toolbox/mcode/example/dfa 3");
			return results;
		}
		
		MapRecord map=null;
		String database=args[0];
		String commandName=args[1];

		int threads= MAX_THREADS;
		if(args.length>2)
			threads=Integer.valueOf(args[2]);
		threads=(threads > MAX_THREADS) ? MAX_THREADS:threads;
		threads=(threads < 1) ? MAX_THREADS:threads;

		String endTime=UNSPECIFIED_SAMPLE;
		if(args.length>3)
			endTime=args[3];

		String startTime=UNSPECIFIED_SAMPLE;
		if(args.length>4)
			startTime=args[4];

		
		ArrayList<Future<Double>> futures=
				new ArrayList<Future<Double>>(threads);
		ExecutorService executor= 
				Executors.newFixedThreadPool(threads);

		

		double fail=0;
		try {
			map = new MapRecord(database,commandName,startTime,endTime);

			for(int i=0;i<threads;i++){
				Future<Double> future= executor.submit(map);
				futures.add(future);
			}
			for( Future<Double> future: futures){
				fail =future.get();
				if(fail>0)
					System.err.println("Future computation failed:  " + future.toString());
			}
			results=map.getResults();
		} catch (InterruptedException e1) {
			e1.printStackTrace();
		} catch (ExecutionException e) {
			e.printStackTrace();
		} 
		executor.shutdown();
		//System.out.println("!!Done: Processed records: " + results.length);
		return results;
	}

}
