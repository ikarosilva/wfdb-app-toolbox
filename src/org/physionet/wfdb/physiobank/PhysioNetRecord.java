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
 * Contributor(s):   -;
 *
 * Changes
 * -------
 * Check: http://code.google.com/p/wfdb-java/list
 */

package org.physionet.wfdb.physiobank;

import java.util.ArrayList;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.physionet.wfdb.Wfdbexec;

public class PhysioNetRecord {

	private String name=new String();
	private ArrayList<String> signalStringList;
	private ArrayList<PhysioNetSignal> signalList;
	private static Logger logger =
			Logger.getLogger(PhysioNetRecord.class.getName());


	public PhysioNetRecord(String RecordName){

		/*
		Level debugLevel = Level.FINEST;//use for debugging Level.FINEST;
		if(debugLevel != null){
			Handler[] handlers =
					Logger.getLogger( "" ).getHandlers();
			for ( int index = 0; index < handlers.length; index++ ) {
				handlers[index].setLevel( debugLevel );
			}
			Logger.getLogger("org.physionet.wfdb.Wfdbexec").setLevel(debugLevel);
			Logger.getLogger("org.physionet.wfdb.physiobank").setLevel(debugLevel);
		}
		*/
		name=RecordName;
		signalStringList = new ArrayList<String>();
		signalList=new ArrayList<PhysioNetSignal>();
		setSignalList();
	}

	public ArrayList<String> getSignalStringList() {
		return signalStringList;
	}

	public void printRecord(){
		for(PhysioNetSignal sig: signalList){
			sig.printSignalInfo();
		}
	}

	public void setSignalList(){
		setSignalList(null);
	}


	public void setSignalList(String descFilter) {
		//Parse information from wfdbdesc to populate the record list
		String[] args=new String[1];
		args[0]=name;
		Wfdbexec wfdbdesc = new Wfdbexec("wfdbdesc");
		wfdbdesc.setArguments(args);
		logger.finest("\n\t***Executing wfdb command");
		ArrayList<String> tmpList= wfdbdesc.execToStringList();
		String startTime=null;
		String lengthTime=null;
		String lengthSample=null;
		String samplingFrequency=null;
		PhysioNetSignal tmpSignal=null;

		//REGEXP Parsers
		String groupRegex="^Group (\\d+), Signal (\\d+):";
		//Regex to parse something like: "Length:    30:05.556 (650000 sample intervals)"
		
		//TODO: find a way to make one single expression with optional day field 
		String lengthRegex="Length:\\s+(\\d+:\\d+.\\d+)\\s+\\((\\d+)\\s+sample\\s+intervals\\)";
		String lengthRegex2="Length:\\s+(\\d+:\\d+:\\d+.\\d+)\\s+\\((\\d+)\\s+sample\\s+intervals\\)";

		Pattern groupPattern = Pattern.compile(groupRegex);
		Pattern lengthPattern = Pattern.compile(lengthRegex);
		Pattern lengthPattern2 = Pattern.compile(lengthRegex2);

		Matcher groupMatch=null;
		Matcher lengthMatch=null;

		logger.fine("parsing list, size= " + tmpList.size());

		for(String i : tmpList){
			logger.finest("parsing :"  + i);
			if(i.startsWith("Starting time: ")){
				startTime=i.replace("Starting time: ","");
			}
			else if (i.startsWith("Length: ") && !(i.contains("Length: not specified")) ) {
				try{
				//String should have a format similar to :Length:    30:05.556 (650000 sample intervals)
				lengthMatch=lengthPattern.matcher(i);
				if (!lengthMatch.find() ){
					//Attempt second matcher for length
					lengthMatch=lengthPattern2.matcher(i);
					lengthMatch.find();
				}
				if(! lengthMatch.group(1).isEmpty())
					lengthTime=lengthMatch.group(1);
				if(! lengthMatch.group(2).isEmpty())
					lengthSample=lengthMatch.group(2);
				} catch (IllegalStateException e){
					System.err.println("Could not match : " +i );
					System.err.println("Attempting to continue...");
				}
			}else if (i.startsWith("Sampling frequency: ")) {
				samplingFrequency=i.replace("Sampling frequency: ","");
			}else if (i.startsWith("Group ")) {
				if(tmpSignal != null){
					if(descFilter == null){
						signalList.add(tmpSignal);
					}else if(descFilter.equals(tmpSignal.getDescription())){					
						signalList.add(tmpSignal);
					}
				}
				tmpSignal=new PhysioNetSignal(signalList.size()+1,name);
				tmpSignal.setStartTime(startTime);
				tmpSignal.setLengthTime(lengthTime);
				tmpSignal.setLengthSamples(lengthSample);
				tmpSignal.setSamplingFrequency(samplingFrequency);

				groupMatch=groupPattern.matcher(i);
				groupMatch.find();
				if(! groupMatch.group(1).isEmpty())
					tmpSignal.setGroup(groupMatch.group(1));
				if(! groupMatch.group(2).isEmpty())
					tmpSignal.setSignalIndex(groupMatch.group(2));

			}else if (i.startsWith(" File: ")) {
				tmpSignal.setFile(i.replace(" File: ",""));
			}else if (i.startsWith(" Description: ")) {
				tmpSignal.setDescription(i.replace(" Description: ",""));
			}else if (i.startsWith(" Gain: ")) {
				tmpSignal.setGain(i.replace(" Gain: ",""));
			}else if (i.startsWith(" Initial value: ")) {
				tmpSignal.setInitialValue(i.replace(" Initial value: ",""));
			}else if (i.startsWith(" Storage format: ")) {
				tmpSignal.setFormat(i.replace(" Storage format: ",""));
			}else if (i.startsWith(" I/O: ")) {
				tmpSignal.setIo(i.replace(" I/O: ",""));
			}else if (i.startsWith(" ADC resolution: ")) {
				tmpSignal.setAdcResolution(i.replace(" ADC resolution: ",""));
			}else if (i.startsWith(" ADC zero: ")) {
				tmpSignal.setAdcZero(i.replace(" ADC zero: ",""));
			}else if (i.startsWith(" Baseline: ")) {
				tmpSignal.setBaseline(i.replace(" Baseline: ",""));
			}else if (i.startsWith(" Checksum: ")) {
				tmpSignal.setCheckSum(i.replace(" Checksum: ",""));
			}			
		} //end of for loop

		//Add last signal to list
		if(tmpSignal != null){
			if(descFilter == null){
				signalList.add(tmpSignal);
			}else if(descFilter.equals(tmpSignal.getDescription())){					
				signalList.add(tmpSignal);
			}
		}
		logger.fine("Done parsing!");

	}

	public ArrayList<PhysioNetSignal> getSignalList() {
		return signalList;
	}

	@SuppressWarnings("unused")
	public static void main(String[] args) {


		// Prints information regarding all databases
		// Currently available at PhysioNet
		/*
		Level debugLevel = null;//use for debugging Level.FINEST;
		if(debugLevel != null){
			Handler[] handlers =
					Logger.getLogger( "" ).getHandlers();
			for ( int index = 0; index < handlers.length; index++ ) {
				handlers[index].setLevel( debugLevel );
			}
			Logger.getLogger("org.physionet.wfdb.Wfdbexec").setLevel(debugLevel);
			Logger.getLogger("org.physionet.wfdb.physiobank").setLevel(debugLevel);
		}
		 */
		PhysioNetRecord re = new PhysioNetRecord(args[0]);
		ArrayList<PhysioNetSignal> sg= re.getSignalList();
		for(PhysioNetSignal mysig : sg)
			mysig.printSignalInfo();
	}

}
