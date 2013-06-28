/*
 * ===========================================================
 * PhysioNet Challenge Score 2013
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
 * Original Author:  Ikaro Silva, 
 * 
 * Last Modified:	 June 28, 2013
 * 
 * Changes
 * -------
 * Check: http://code.google.com/p/wfdb-java/list
 * 
 *
 */

package org.physionet.wfdb.concurrent;
import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Scanner;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class Dfa implements Callable<Double>{
	private static final int THREADS=1;//Runtime.getRuntime().availableProcessors();
	private final double[] data; //Once initialized should be read only
	private final int N;		//Size of data
	private final int[] scales; //Once initialized should be read only
	private final BlockingQueue<Integer> tasks;
	private double[] results;

	Dfa(ArrayList<Double> x) throws InterruptedException{

		//Zero mean the data, itegrate, and initialize it
		double mx=0, integrator=0;

		N=x.size();
		data = new double[N];
		for(double i : x)
			mx+=i;
		mx=mx/((double) N);
		for(int i=0;i<N;i++){
			//integrator+=x.get(i)-mx;
			data[i]=x.get(i);//integrator;
		}

		//Set task queue according to scales to be calculated
		int scaleSize=1;//(int) (Math.round(N/4.0)-4);
		System.err.println("Scales from: 4 to " + Math.round(N/4.0));
		scales = new int[scaleSize];
		results=new double[scales.length];
		tasks=new ArrayBlockingQueue<Integer>(scales.length);
		scales[0]=N;
		for(int i=0;i<scales.length;i++){
			//scales[i]=4+i;
			tasks.put(i);
		}

	}

	public Double call(){
		double x=0.0;
		Integer scaleInd=0;
		long id=Thread.currentThread().getId();
		while ((scaleInd = tasks.poll()) != null ){ 
			//System.out.println(id + ": runing scale:" + scales[scaleInd]);
			results[scaleInd]=compute(scales[scaleInd]);
			//System.out.println(id + ": " + scales[scaleInd] + " dfa= " + results[scaleInd]);
		}
		return x;
	}



	public double compute(int scale){
		//Compute 
		//For each block of size "scale" calculate the local linear trend,
		//subtract it from the time series, and calculate the RMS of this residue

		//Local linear trend is based on recursive least square estimation technique from
		//"Fundamentals of Kalman Filtering: A Practical Approach", Zarchan ad Musoff, pg 125
		double K1=0, K2=0, err=0, m = 0.0, b=0.0, k=1.0;
		double Ts=1; //step size in x-axis (is evenly sampled, use 1)
		double detrendVar=0, tmp=0;
		double sumX=0;
		double sumTX=0;
		double C=0;
		double D=0;
		int Ncorrect=(int) (scale*(N/((double) scale)));//Correct for cases where we were not able to calculate last box
		for(int n=0;n<Ncorrect;n++){
			
			if(n%scale ==0){
				//Get detrended residue power, and keep running average over entire waveform
				if(n != 0){
					for(int i=0;i<k;i++){
						tmp=(data[(int) (n-k+i+1)] - b -m*i);
						detrendVar+=tmp*tmp;
						System.err.print(data[n] + " ");
					}
					System.err.println("");
				}
				//Reset state of least square estimator
				K1=0.0;
				K2=0.0;
				err=0.0;
				m=0.0;
				k=1.0;
				b=0.0;
			}

			//Perform recursive least square estimation
			System.err.println("b= "+ b +" e= " + err + " m= " + m
					+" k= " + k + " data= " + data[n]);
			
			err=data[n] - b -m*Ts;
			K1=(4*k-2)/(k*k+k);
			K2=6/(Ts*(k*k+k));
			b=b + m*k + K1*err;
			m=m + K2*err;
			k=k+1;
			
			sumX+=data[n];
			sumTX +=n*data[n];
			C +=n;
			D += (n*n);
		}

		
		double den= (Ncorrect*D- C*C);
		D=D/den;
		double A=Ncorrect/den;
		C=C/den;
		double optb= D*sumX - C*sumTX; 
		double optm= -C*sumX + A*sumTX;
		System.err.println("optb= "+ optb +" optm = "+ optm );
		return 0.5*Math.log10( detrendVar/((double) Ncorrect) );

	}



	public static void main(String[] args){

		ArrayList<Future<Double>> futures=
				new ArrayList<Future<Double>>(THREADS);
		ExecutorService executor= 
				Executors.newFixedThreadPool(THREADS);
		Scanner in = null;
		if (args!=null && args.length>0 && args[0].equals("-d")){
			try {
				in = new Scanner(new File(args[1]));
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		} else {
			in = new Scanner(System.in);
		}

		ArrayList<Double> numbers = new ArrayList<Double>();
		double tmp;
		//while (in.hasNextDouble())
		//    numbers.add(in.nextDouble());
			
		numbers.add(1.2);
		numbers.add(0.2);
		numbers.add(2.9);
		numbers.add(2.1);
		
		Dfa dfa=null;
		try {
			System.err.println("Initializing constructor with: " + THREADS + " threads, N= "+ numbers.size());
			dfa = new Dfa(numbers);
			long start=System.currentTimeMillis();
			System.err.println("Using: " + THREADS + " threads");
			for(int i=0;i<THREADS;i++){
				Future<Double> future= executor.submit(dfa);
				futures.add(future);
			}
			for( Future<Double> future: futures){
				tmp =future.get();
			}
			long end=System.currentTimeMillis();
			System.err.println(" !!Finished -> Time= " + (end-start)/1000.0);

		} catch (InterruptedException e1) {
			e1.printStackTrace();
		} catch (ExecutionException e) {
			e.printStackTrace();
		} 
		executor.shutdown();
		
		for(int i=0;i<dfa.results.length;i++)
			System.out.println(Math.log10(i+4) + " " + dfa.results[i]); 
		
	}

}
