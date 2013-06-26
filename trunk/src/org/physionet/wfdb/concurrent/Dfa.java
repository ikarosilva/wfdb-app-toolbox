
package org.physionet.wfdb.concurrent;
import java.util.ArrayList;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class Dfa implements Callable<Double>{
	private static final int THREADS=Runtime.getRuntime().availableProcessors();
	private final int  quotient;
	private final int  remainder;
	private final double[] data; //Once initialized should be read only
	private final int[] scales; //Once initialized should be read only
	private final int[] taskSize;
	private final BlockingQueue<Integer> tasks;
	private double[] results;

	Dfa(double[] x, int[] scales) throws InterruptedException{
		
		//Zero mean the data, itegrate, and initialize it
		double mx=0, integrator=0;
		data = new double[x.length];
		for(double i : x)
			mx+=i;
		mx=mx/((double) data.length);
		for(int i=0;i<data.length;i++){
			integrator+=x[i]-mx;
			data[i]=integrator;
		}
		
		
		//Set task queue according to scales to be calculated
		this.scales=scales;
		results=new double[scales.length];
		
		quotient=scales.length/THREADS;
		remainder=scales.length%THREADS;
		taskSize=new int[THREADS];
		tasks=new ArrayBlockingQueue<Integer>(THREADS);
		for(int i=0;i<THREADS;i++){
			taskSize[i]=quotient;
			if(remainder>i)
				taskSize[i]++;
			tasks.put(i*quotient);
		} 
	}

	public Double call(){
		double x=0;
		int start=0, end =0;
		long id=Thread.currentThread().getId();
		try {
			start = tasks.take();
			end=start+taskSize[start/quotient];
			System.out.println(id + ": runing task from :" + start + 
					" to " + (end-1));
			
			x=compute(start,end);
			System.out.println(id + ": finished task from :" + start + 
					" to " + end + " sum= " + x);
		} catch (InterruptedException e) {
			System.err.println("Could not access task queue");
			e.printStackTrace();
		}
		return x;
	}

	
	
	public double compute(int start, int end){
		//Compute DFA within an array chunk
		double x=0;
		for(int i=start;i<end;++i){
			x+=Math.sqrt(data[i]);
		}
		return x;
	}
	
	
	
	public static void main(String[] args){
		ArrayList<Future<Double>> futures=
				new ArrayList<Future<Double>>(THREADS);
		ExecutorService executor= 
				Executors.newFixedThreadPool(THREADS);

		int N=80;
		double sum=0;
		int[] scales={5,10,15,20,25,30,35,40,45,50,55,60,65,70};
		double[] data=new double[N];
		for(int i=0;i<N;i++)
			data[i]=Math.random();

		Dfa dfa=null;
		try {
			System.out.println("Initializing constructor");
			dfa = new Dfa(data,scales);
			long start=System.currentTimeMillis();
			System.out.println("Using: " + THREADS + " threads");
			for(int i=0;i<THREADS;i++){
				Future<Double> future= executor.submit(dfa);
				futures.add(future);
			}
		
			for( Future<Double> future: futures){
				sum+=future.get();
			}
			long end=System.currentTimeMillis();
			System.out.println("sum is = " + sum + " time= "+
					(end-start)/1000.0);
		} catch (InterruptedException e1) {
			e1.printStackTrace();
		} catch (ExecutionException e) {
			e.printStackTrace();
		}
		executor.shutdown();

	}

}
