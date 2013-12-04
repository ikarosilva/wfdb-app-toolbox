package org.physionet.wfdb;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.Map;
import java.util.Vector;
import java.util.logging.Logger;

public class SystemSettings {

	private final static Logger logger = Logger.getLogger(Wfdbexec.class.getName());
	private static boolean isLoadedLibs=false;
	
	@SuppressWarnings("unchecked")
	public static String[] getLoadedLibraries(Object o) {
		final ClassLoader loader=o.getClass().getClassLoader();
		Vector<String> libraries=null;
		try {
			final java.lang.reflect.Field LIBRARIES= 
					ClassLoader.class.getDeclaredField("loadedLibraryNames");
			LIBRARIES.setAccessible(true);
			libraries = (Vector<String>) LIBRARIES.get(loader);
		} catch (NoSuchFieldException | SecurityException |
				IllegalArgumentException | IllegalAccessException e) {
			e.printStackTrace();
		}
		System.out.println("\nSystemSetting --libraries: " + libraries.toArray(new String[] {}));
		return libraries.toArray(new String[] {});
	}

	public static String getFileSeparator(){
		return System.getProperty("file.separator");		
	}
	public static String getosArch(){
		System.out.println("\nSystemSetting --Arch-" + System.getProperty("os.arch"));
		return System.getProperty("os.arch");
	}

	public static String getOsName(){
		String osName=System.getProperty("os.name");
		osName=osName.replace(" ","");
		osName=osName.toLowerCase();
		if(osName.startsWith("windows")){
			osName="windows"; //Treat all Windows versions the same for now
		}
		System.out.println("\nSystemSetting --OS-" +osName);
		return osName;
	}

	public static void loadLibs(){
		if(isLoadedLibs == false){
		//System.load(SystemSettings.getWFDB_NATIVE_BIN()+ 
		//		"bin" + getFileSeparator() + "libcurl-4.dll");
		//System.loadLibrary("libcurl.dll.a");
		//System.out.println("assing: " + SystemSettings.getWFDB_NATIVE_BIN()+
		//		"lib" + getFileSeparator() + "libcurl");
		System.out.println("\nSystemSetting --loadingLibCurl from: " +
				SystemSettings.getWFDB_NATIVE_BIN()+
				"lib" + getFileSeparator() + "libcurl");
		 	isLoadedLibs=true;
		}
	}

	public static String getLD_PATH(){
		ProcessBuilder launcher = new ProcessBuilder();
		Map<String,String> env = launcher.environment();
		String LD_PATH="";
		String WFDB_NATIVE_BIN=getWFDB_NATIVE_BIN();
		String osName=getOsName();
		String tmp="", pathSep="";
		String OsPathName;
		if(osName.contains("windows")){
			LD_PATH=env.get("Path");pathSep=";";
			OsPathName="PATH";
		}else if(osName.contains("macosx")){
			LD_PATH=env.get("DYLD_LIBRARY_PATH");pathSep=":";
			OsPathName="DYLD_LIBRARY_PATH";
		}else{
			LD_PATH=env.get("LD_LIBRARY_PATH");pathSep=":";
			tmp=WFDB_NATIVE_BIN + "lib:" + WFDB_NATIVE_BIN + "lib64";
			OsPathName="LD_LIBRARY_PATH";
		}
		tmp=WFDB_NATIVE_BIN + "lib" + pathSep + WFDB_NATIVE_BIN + "bin"
				+pathSep +  WFDB_NATIVE_BIN + "lib64";
		if(LD_PATH == null){
			LD_PATH=tmp;
		}else if(LD_PATH.indexOf(tmp) <0){
			//Only add if path is not present already
			LD_PATH=LD_PATH+pathSep+tmp;
		}
		System.out.println("\nSystemSetting --Configuring PATH to: " + LD_PATH);
		env.put(OsPathName,LD_PATH);
		return LD_PATH;
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
		int tmp = packageDir.lastIndexOf(getFileSeparator());
		packageDir=packageDir.substring(0,tmp+1);
		packageDir=packageDir.replace("file:","");
		System.out.println("\nSystemSetting --WFDB HOME: " + packageDir);
		return packageDir.toString();
	}

	public synchronized static String getWFDB_NATIVE_BIN() {
		String WFDB_NATIVE_BIN;
		String WFDB_JAVA_HOME=getWFDB_JAVA_HOME();
		//Set path to executables based on system/arch
		WFDB_NATIVE_BIN= WFDB_JAVA_HOME+ "mcode" + getFileSeparator()+"nativelibs" + getFileSeparator() + 
				getOsName().toLowerCase() + "-" + getosArch().toLowerCase() 
				+ getFileSeparator() ;
		System.out.println("\nSystemSetting --WFDB NATIVE BIN: " + WFDB_NATIVE_BIN);
		return WFDB_NATIVE_BIN;
	}

	public static void main(String[] args) throws Exception {
		System.out.println(getWFDB_NATIVE_BIN());
		System.out.println(getWFDB_JAVA_HOME());
		loadLibs();
		Wfdbexec rdsamp=new Wfdbexec("rdsamp");
		String[] arg={"-r","mitdb/100","-t","s3"};
		rdsamp.setArguments(arg);
		System.out.println("executing rdsamp");
		ArrayList<String> resp = rdsamp.execToStringList();
		rdsamp.setInitialWaitTime(10000);
		for(String str: resp)
			System.out.println("rdsamp: " + str);
		System.out.println("***Done");
	}

}