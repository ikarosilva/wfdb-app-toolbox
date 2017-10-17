package org.physionet.wfdb;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.Map;

public class SystemSettings {

	static String fsep= System.getProperty("file.separator");

	public static void loadCurl(Boolean customArch){

		if(getOsName().contains("windows")){
			//On Windows, load the shipped curl library
			System.load(SystemSettings.getWFDB_NATIVE_BIN(customArch) 
					+ "\\bin\\libcurl-4.dll" );
		}else if(getOsName().contains("mac")){
			String libCurlName= SystemSettings.getWFDB_NATIVE_BIN(customArch) 
					+ "bin/libcurl.4.dylib";
			SecurityManager security = System.getSecurityManager();
			if(security != null){
				security.checkLink(libCurlName);
			}
			System.load(libCurlName);
		}

	}

	private static void loadLib(String libName, Boolean customArch){
		if(getOsName().contains("windows")){
			try {
				System.load(SystemSettings.getWFDB_NATIVE_BIN(customArch) 
						+ "\\bin\\lib"  + libName + ".dll");
			} catch (UnsatisfiedLinkError e) {
				System.err.println("Native code library failed to load.\n" + e);
				System.exit(1);
			}

		}else if(getOsName().contains("mac")){
			System.load(SystemSettings.getWFDB_NATIVE_BIN(customArch) 
					+ "/lib/lib" + libName + ".dylib");
		}else{
			//Default to Linux
			System.load(SystemSettings.getWFDB_NATIVE_BIN(customArch) 
					+ "/lib/lib" + libName + ".so");
		}
	}

	public static void loadLib(String libName){
		try {
			loadLib(libName, true);
		}
		catch (UnsatisfiedLinkError e) {
			loadLib(libName, false);
		}
	}

	public static String getosArch(){
		//Returns the JVM type
		return System.getProperty("os.arch");
	}

	public static String getOsName(){
		String osName=System.getProperty("os.name");
		osName=osName.replace(" ","");
		osName=osName.toLowerCase();
		if(osName.startsWith("windows")){
			osName="windows"; //Treat all Windows versions the same for now
		}
		return osName;
	}

	public static String getLD_PATH(boolean customArchFlag){
		ProcessBuilder launcher = new ProcessBuilder();
		Map<String,String> env = launcher.environment();
		String LD_PATH="";
		String WFDB_NATIVE_BIN=getWFDB_NATIVE_BIN(customArchFlag);
		String osName=getOsName();
		String tmp="", pathSep="";
		String OsPathName;
		if(osName.contains("windows")){
			LD_PATH=env.get("Path");pathSep=";";
			OsPathName="PATH";
			tmp=WFDB_NATIVE_BIN + "bin" + pathSep + WFDB_NATIVE_BIN + "lib";
		}else if(osName.contains("macosx")){
			LD_PATH=env.get("DYLD_LIBRARY_PATH");pathSep=":";
			OsPathName="DYLD_LIBRARY_PATH";
			tmp=WFDB_NATIVE_BIN + "bin" + pathSep 
					+ WFDB_NATIVE_BIN + "lib64" + pathSep 
					+ WFDB_NATIVE_BIN + "lib";
		}else{
			LD_PATH=env.get("LD_LIBRARY_PATH");pathSep=":";
			OsPathName="LD_LIBRARY_PATH";
			tmp=WFDB_NATIVE_BIN + "bin" + pathSep 
					+ WFDB_NATIVE_BIN + "lib64" + pathSep 
					+ WFDB_NATIVE_BIN + "lib";
		}

		if(LD_PATH == null){
			LD_PATH=tmp;
		}else if(LD_PATH.indexOf(tmp) <0){
			//Only add if path is not present already
			LD_PATH=tmp+pathSep+LD_PATH;
		}
		return LD_PATH;
	}

	public static int getNumberOfProcessors(){
		return Runtime.getRuntime().availableProcessors();
	}

	public static String getWFDB_JAVA_HOME(){
		String packageDir = null;
		try {
			packageDir=URLDecoder.decode(
					Wfdbexec.class.getProtectionDomain().getCodeSource().getLocation().getPath(),"utf-8");
			packageDir = new File(packageDir).getPath();
		} catch (UnsupportedEncodingException e) {
			System.err.println("Could not get path location of WFDB JAR file.");
			e.printStackTrace();
		}
		int tmp = packageDir.lastIndexOf(fsep);
		packageDir=packageDir.substring(0,tmp+1);
		packageDir=packageDir.replace("file:","");
		return packageDir.toString();
	}

	public synchronized static String getWFDB_NATIVE_BIN(boolean customArchFlag) {
		String WFDB_NATIVE_BIN;
		String WFDB_JAVA_HOME=getWFDB_JAVA_HOME();
		//Set path to executables based on system/arch and customArchFlga
		if(customArchFlag){
			WFDB_NATIVE_BIN= WFDB_JAVA_HOME+ "nativelibs" + fsep + "custom"+ fsep;
		}else{
			WFDB_NATIVE_BIN= WFDB_JAVA_HOME+ "nativelibs" + fsep + 
					getOsName().toLowerCase()+ fsep ;
		}
		return WFDB_NATIVE_BIN;
	}

}
