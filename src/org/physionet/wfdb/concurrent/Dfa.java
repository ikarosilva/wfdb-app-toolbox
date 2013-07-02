/*
 * ===========================================================
 * DFA 2013
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
 *  Algorith contains elements based on DFA C version:
 *  				http://www.physionet.org/physiotools/dfa/dfa.c
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
import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
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

		//Set task queue according to scales to be calculated as in the C code
		double boxRatio=Math.pow(2.0, 1.0/8.0);
		int minBox=4;
		int maxBox= N/4;
		int scaleSize=(int) (Math.log10(maxBox/minBox)/Math.log10(boxRatio) +1.5) -5;
				System.err.println("Scales from: 4 to " + maxBox + " ( " + scaleSize 
				+ " scales)") ;
		scales = new int[scaleSize];
		results=new double[scales.length];
		tasks=new ArrayBlockingQueue<Integer>(scales.length);
		int thisScale, oldScale=0;
		int index=0;
		for(int i=0;i<scales.length+5;i++){
			thisScale=(int) (minBox*Math.pow(boxRatio,i) + 0.5);
			if(thisScale != oldScale){
				scales[index]=thisScale;
				tasks.put(index);
				oldScale=thisScale;
				index++;
			}		
		}

	}

	public Double call(){
		double x=0.0;
		Integer scaleInd=0;
		long id=Thread.currentThread().getId();
		while ((scaleInd = tasks.poll()) != null ){ 
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
		double K1=0, K2=0, e=0, m = 0.0, b=0.0, k=1.0;
		double Ts=1; //step size in x-axis (is evenly sampled, use 1)
		double mse=0, err=0;
		int Ncorrect=(int) (scale*(N/((double) scale)));//Correct for cases where we were not able to calculate last box
		for(int n=0;n<Ncorrect;n++){
			
			if(n%scale ==0){
				//Get detrended residue power, and keep running average over entire waveform
				if(n != 0){
					for(int i=0;i<k;i++){
						err= b + m*i - data[(int) (n-k+i+1)];
						//System.out.println("err= " + err);
						mse+=err*err;
					}
					//System.err.println("");
				}
				//Reset state of least square estimator
				K1=0.0;
				K2=0.0;
				e=0.0;
				m=0.0;
				k=1.0;
				b=0.0;
			}
			//TODO: use ls estimator of Scharf pg. 385 to see if performance is 
			//improved

			//Perform recursive least square estimation			
			e=data[n] - b -m*(k-1);
			K1=(4*k-2)/(k*k+k);
			K2=6/( Ts*(k*k+k) );
			b=b + m*Ts + K1*e;
			m=m + K2*e;
			k=k+1;
			System.err.println(data[n]);
		}
		//System.err.println("mse=" + mse);
		System.err.println("a=" + m + " b= " + b);
		return 0.5*Math.log10( mse/((double) Ncorrect) );

	}



	public static void main(String[] args){

		ArrayList<Future<Double>> futures=
				new ArrayList<Future<Double>>(THREADS);
		ExecutorService executor= 
				Executors.newFixedThreadPool(THREADS);
		//Scanner in = null;
		BufferedReader br = null;
		
		if (args!=null && args.length>0 && args[0].equals("-d")){
			try {
				//in = new Scanner(new File(args[1]));
				br = new BufferedReader(new FileReader(new File(args[1])));
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		} else {
			//in = new Scanner(System.in);
			br = new BufferedReader(new InputStreamReader(System.in));
		}

		ArrayList<Double> numbers = new ArrayList<Double>();
		numbers.ensureCapacity(100000);
		double tmp;
		String line=null;
		double index=0, y;
		try {
			while ( ( line = br.readLine() )!= null ){
				//numbers.add(Double.valueOf(line));
				index=index+1;
				y=index*1 + 0.0; 
				numbers.add(y);
			}
		} catch (IOException e2) {
			e2.printStackTrace();
		}		
		Dfa dfa=null;
		try {
			dfa = new Dfa(numbers);
			for(int i=0;i<THREADS;i++){
				Future<Double> future= executor.submit(dfa);
				futures.add(future);
			}
			for( Future<Double> future: futures){
				tmp =future.get();
			}
		} catch (InterruptedException e1) {
			e1.printStackTrace();
		} catch (ExecutionException e) {
			e.printStackTrace();
		} 
		executor.shutdown();
		
		for(int i=0;i<dfa.results.length;i++)
			System.out.println(Math.log10(dfa.scales[i]) + " " + dfa.results[i]); 
		
	}

}
