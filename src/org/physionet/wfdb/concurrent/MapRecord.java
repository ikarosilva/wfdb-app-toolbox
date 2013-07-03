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
 * Last Modified:	 July 1, 2013
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
	private static final int THREADS=1;//Runtime.getRuntime().availableProcessors();
	private final int N;		//Total number of records
	private final BlockingQueue<String> tasks;
	private final HashMap<String,Integer> index;
	private double[][] results;
	private static String commandName;
	private static String commandDir;

	MapRecord(String dataBase,String commandName,String commandDir) throws InterruptedException{

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
		this.commandName=commandName;
		this.commandDir=commandDir;
		for(PhysioNetRecord rec : recordList){
			tasks.put(rec.getRecordName());
			index.put(rec.getRecordName(),ind);
			ind++;
		}

	}

	public double[][] getResults(){
		return results;
	}

	public Double call(){
		double fail=0;
		String taskInd;
		long id=Thread.currentThread().getId();
		while ((taskInd = tasks.poll()) != null ){ 
			System.out.println("Thread [" + id + "]: Processing: " + taskInd);
			results[index.get(taskInd)]=compute(taskInd).clone();
		}
		return fail;
	}


	public double[] compute(String record){

		Wfdbexec rdsamp=new Wfdbexec("rdsamp");
		Wfdbexec exec=new Wfdbexec(commandName,commandDir);
		String[] arguments={"-r",record};
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

		ArrayList<Future<Double>> futures=
				new ArrayList<Future<Double>>(THREADS);
		ExecutorService executor= 
				Executors.newFixedThreadPool(THREADS);

		MapRecord map=null;
		String database="aami-ec13";
		String commandName="dfa";
		String commandDir="/home/ikaro/workspace/wfdb-app-toolbox/mcode/example/";

		double[][] results = null;
		double fail=0;
		try {
			map = new MapRecord(database,commandName,commandDir);

			for(int i=0;i<THREADS;i++){
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
		System.out.println("!!Done: Processed records: " + results.length);
		for(int i=0;i<results.length;i++){
			System.out.println("results[" + i + "] (" + results[i].length+  ") : ");
			for(int k=0;k<results[i].length;k++)
				System.out.print(results[i][k] + " ");
			System.out.println("");
		}
	}

}
