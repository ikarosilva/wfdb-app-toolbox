/*
 * ===========================================================
 * Wfdbexec 2013
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
import java.util.concurrent.atomic.AtomicLong;

import org.physionet.wfdb.Wfdbexec;
import org.physionet.wfdb.physiobank.PhysioNetDB;
import org.physionet.wfdb.physiobank.PhysioNetRecord;

public class  ConcurrentWfdbexec implements Callable<Double>{
	private static final int MAX_THREADS=Runtime.getRuntime().availableProcessors();
	private final int N;		//Total number of records
	private final BlockingQueue<String> tasks;
	private final HashMap<String,Integer> index;
	private AtomicLong results;  //Keep track of processed records
	private final String commandName;
	private final String[] commandInputArgs;

	public ConcurrentWfdbexec(ArrayList<String> recordList,String commandName,String[] args) throws InterruptedException{
		//Set task queue 
		N= recordList.size();
		;
		tasks=new ArrayBlockingQueue<String>(N);
		index=new HashMap<String,Integer>();
		commandInputArgs=args;
		Integer ind=0;
		this.commandName=commandName;
		for(String rec : recordList){
			tasks.put(rec);
			index.put(rec,ind);
			ind++;
		}
	}

	public static int getNumberOfProcessors(){return MAX_THREADS;}
	
	public ConcurrentWfdbexec(String dataBase,String commandName,String[] args) throws Exception{
		//Initialize record list
		PhysioNetDB db = new PhysioNetDB(dataBase);
		db.setDBRecordList();
		ArrayList<PhysioNetRecord> recordList = db.getDBRecordList();

		//Set task queue 
		N= recordList.size();
		results.set(0);
		tasks=new ArrayBlockingQueue<String>(N);
		index=new HashMap<String,Integer>();
		Integer ind=0;
		this.commandName=commandName;
		commandInputArgs=args;
		for(PhysioNetRecord rec : recordList){
			tasks.put(rec.getRecordName());
			index.put(rec.getRecordName(),ind);
			ind++;
		}
	}

	public  long getResults(){
		return results.get();
	}

	public HashMap<String,Integer> getIndexMap(){
		return index;
	}

	public Double call(){
		double fail=0.0;
		String taskInd;
		//long id=Thread.currentThread().getId();
		while ((taskInd = tasks.poll()) != null ){ 
			//System.out.println("Thread [" + id + "]: Processing: " + taskInd);
			//results[index.get(taskInd)]=compute(taskInd).clone();
			fail = compute(taskInd);
		}
		return Double.valueOf(fail);
	}


	public double compute(String record){

		Wfdbexec exec=new Wfdbexec(commandName,"",Wfdbexec.customArchFlag);
		exec.setArguments(commandInputArgs);
		
		//Execute command
		ArrayList<String> y = null; //standard error
		long out=0;
		try {
			y=exec.execToStringList();
			//For case where the command does not output data
			//such as in those generating annotation files, output NaNs
			out=1;
		} catch (Exception e) {
			e.printStackTrace();
			if(y != null)
				System.err.println(y);
		}
		return out;
	}


	public static String[] getRecordList(String[] args) throws Exception{


		if(args.length<3){
			System.out.println("Usage: ConcurrentWfdbexec databaseName commandDir nThreads commandName commandInputArgs");
		}
		ConcurrentWfdbexec map=null;
		String database=args[0];
		String commandName=args[3];
		String[] commandArgs={args[4]};

		try {
			map = new ConcurrentWfdbexec(database,commandName,commandArgs);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		HashMap<String, Integer> indexMap = map.getIndexMap();
		String[] recList=new String[indexMap.size()];
		indexMap.keySet().toArray(recList);

		//System.out.println("!!Done: Processed records: " + results.length);
		return recList;
	}

	public long start(String[] args) throws Exception{
		
		if(args.length<3){
			System.out.println("Usage: ConcurrentWfdbexec databaseName fullpathTocommandName nThreads stopTime startTime");
			return results.get();
		}
		
		ConcurrentWfdbexec map=null;
		String database=args[0];
		String commandName=args[1];

		int threads= MAX_THREADS;
		if(args.length>2)
			threads=Integer.valueOf(args[2]);
		threads=(threads > MAX_THREADS) ? MAX_THREADS:threads;
		threads=(threads < 1) ? MAX_THREADS:threads;
		
		ArrayList<Future<Double>> futures=
				new ArrayList<Future<Double>>(threads);
		ExecutorService executor= 
				Executors.newFixedThreadPool(threads);

		double fail=0;
		try {
			map = new ConcurrentWfdbexec(database,commandName,args);

			for(int i=0;i<threads;i++){
				Future<Double> future= executor.submit(map);
				futures.add(future);
			}
			for( Future<Double> future: futures){
				fail =future.get();
				if(fail>0)
					System.err.println("Future computation failed:  " + future.toString());
			}
			results.addAndGet((long) fail);
		} catch (InterruptedException e1) {
			e1.printStackTrace();
		} catch (ExecutionException e) {
			e.printStackTrace();
		} 
		executor.shutdown();
		//System.out.println("!!Done: Processed records: " + results.length);
		return results.get();
	}

}
