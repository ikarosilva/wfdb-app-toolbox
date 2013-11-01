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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.logging.Logger;
public class PhysioNetDB {

	private String name;
	private String info;
	private URL url;
	private static final String DB_URL="http://physionet.org/physiobank/database/pbi/";
	private static final String DB_LIST="http://physionet.org/physiobank/database/DBS";
	private ArrayList<PhysioNetRecord> dbRecordList;
	private static Logger logger =
			Logger.getLogger(PhysioNetRecord.class.getName());
	
	public PhysioNetDB(String Name){
		name=Name;
		url=setDBURL();
		info=setInfo();
		dbRecordList = new ArrayList<PhysioNetRecord>();

		// Prints information regarding all databases
		// Currently available at PhysioNet
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

	}

	private PhysioNetDB(String Name,String Info){
		name=Name;
		info=Info;
		url=setDBURL();
		dbRecordList = new ArrayList<PhysioNetRecord>();
	}

	public String getname() {
		return name;
	}
	public ArrayList<PhysioNetRecord> getDBRecordList() throws Exception{
		if(dbRecordList.isEmpty()){
			this.setDBRecordList();
		}
		return dbRecordList;
	}
	public String getinfo() {
		return info;
	}
	public URL getURL() {
		return url;
	}

	public static List<PhysioNetDB> getPhysioNetDBList(){
		String inputLine;
		BufferedReader in = null;
		List<PhysioNetDB> physionetDBList = new ArrayList<PhysioNetDB>();
		try {
			URL oracle = new URL(DB_LIST);
			in = new BufferedReader(
					new InputStreamReader(oracle.openStream()));
			String[] tmpStr;
			String tmpname;
			String tmpInfo;
			while ((inputLine = in.readLine()) != null){
				logger.finest("\n\t***Reading URL: \n\t" + inputLine);
				tmpStr=inputLine.split("\\t");
				tmpname=tmpStr[0];
				tmpInfo=(inputLine.replaceFirst(tmpname,"")).replaceAll("\\t","");
				physionetDBList.add(new PhysioNetDB(tmpname,tmpInfo));
			}			
			logger.fine("\n\t*** physionetDBList Size: \n\t" + 
					physionetDBList.size());
			in.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return physionetDBList;
	}

	public static HashMap<String,PhysioNetDB> getPhysioNetDBMap(){
		String inputLine;
		BufferedReader in = null;
		HashMap<String,PhysioNetDB> physionetDBMap= new HashMap<String,PhysioNetDB>();
		try {
			URL oracle = new URL(DB_LIST);
			in = new BufferedReader(
					new InputStreamReader(oracle.openStream()));
			String[] tmpStr;
			String tmpname;
			String tmpInfo;
			while ((inputLine = in.readLine()) != null){
				logger.finest("\n\t***Reading URL: \n\t" + inputLine);
				tmpStr=inputLine.split("\\t");
				tmpname=tmpStr[0];
				tmpInfo=(inputLine.replaceFirst(tmpname,"")).replaceAll("\\t","");
				physionetDBMap.put(tmpname,new PhysioNetDB(tmpname,tmpInfo));
			}			
			in.close();
			logger.fine("\n\t*** physionetDBMap Size: \n\t" + 
					 physionetDBMap.size());
		} catch (IOException e) {
			e.printStackTrace();
		}
		return physionetDBMap;
	}

	public void printDBInfo(){
		System.out.println(name);
		System.out.println("\tDescription: "+ info);
		System.out.println("\tURL: "+ url);
	}
	
	public String getDBInfo(){
		String str=name + "\n\tDescription: "+ info + "\n\tURL: "+ url;
		return str;
	}

	public void printDBRecordList() throws Exception{

		this.getDBRecordList();
		this.printDBInfo();
		for(PhysioNetRecord rec : dbRecordList){
			rec.printRecord();
		}
	}

	public static void printDBList(List<PhysioNetDB> pnDB ) {
		// Prints information regarding all databases in pnDB 
		List<PhysioNetDB> pnDBList = PhysioNetDB.getPhysioNetDBList();
		for(PhysioNetDB db : pnDBList){
			db.printDBInfo();
		}
	}

	public static void printDBList() {
		// Prints information regarding all databases
		// Currently available at PhysioNet
		List<PhysioNetDB> pnDBList = PhysioNetDB.getPhysioNetDBList();
		Collections.sort(pnDBList,PhysioNetDB.DBNameComparator);
		for(PhysioNetDB db : pnDBList){
			db.printDBInfo();
		}
	}

	private URL setDBURL() {
		logger.finer("\n\t***Setting URL: \n\t" + DB_URL + name);
		try {
			return new URL(DB_URL + name.replaceAll("/","_"));
		} catch (MalformedURLException e) {
			e.printStackTrace();
			return null;
		}
	}

	private String setInfo() {
		String inputLine;
		BufferedReader in = null;
		String desc="";
		try {
			URL pnb = new URL(DB_LIST);
			in = new BufferedReader(
					new InputStreamReader(pnb.openStream()));
			String[] tmpStr;
			while ((inputLine = in.readLine()) != null){
				tmpStr=inputLine.split("\\t");
				if(tmpStr[0].compareTo(name)==0){
					desc=(inputLine.replaceFirst(tmpStr[0],"")).replaceAll("\\t","");
					break;
				}
			}			
			in.close();
		} catch (IOException e) {
			e.printStackTrace();
		}		
		return desc;
	}

	public void setDBRecordList() throws Exception{
		String inputLine;
		BufferedReader in = null;
		String[] tmpStr;
		String recname="";
		ArrayList<String> recList = null;
		try {
			in = new BufferedReader(
					new InputStreamReader(url.openStream()));
			while ((inputLine = in.readLine()) != null){
				tmpStr=inputLine.split("\\t");
				logger.finest("\n\t***Reading URL: \n\t" + inputLine);
				if(tmpStr[0].compareTo(recname) != 0){
					//New record, save the last one and
					if(!recname.isEmpty()){
						dbRecordList.add(new PhysioNetRecord(tmpStr[0]));
					}
					recname=tmpStr[0];
					recList=null;
					recList=new ArrayList<String>();
				}
				// Same, record, append to the signal list
				recList.add(new String(inputLine.replaceFirst(recname,"")));
			}			
			in.close();
			logger.fine("\n\t***Rec List Size: \n\t" + recList.size());
		} catch (IOException e) {
			e.printStackTrace();
		}	
	}


	public static Comparator<PhysioNetDB> DBNameComparator = new Comparator<PhysioNetDB>() {
		public int compare(PhysioNetDB db, PhysioNetDB anotherDB) {
			String Name1 = db.getname().toUpperCase();
			String Name2 = anotherDB.getname().toUpperCase();
			if (!(Name1.equals(Name2)))
				return Name1.compareTo(Name2);
			else
				return Name1.compareTo(Name2);
		}
	};


	/*
	public static void main(String[] args) {
		PhysioNetDB db = new PhysioNetDB("mitdb");
		db.setDBRecordList();
		db.printDBRecordList();

	}
*/	

	public static List<PhysioNetDB> main() {

		// Prints information regarding all databases
		// Currently available at PhysioNet
		return PhysioNetDB.getPhysioNetDBList();
	
	}

	
}
