package org.physionet.wfdb;

import java.util.Map;
import java.util.Vector;
import java.util.logging.Logger;

public class SystemSettings {

	private final static Logger logger = Logger.getLogger(Wfdbexec.class.getName());
			
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
       logger.finest("\nSystemSetting --libraries: " + libraries.toArray(new String[] {}));
        return libraries.toArray(new String[] {});
    }
    
	public static String getfileSeparator(){
		return System.getProperty("file.separator");
	}
	public static String getosArch(){
		logger.finest("\nSystemSetting --Arch-" + System.getProperty("os.arch"));
	    return System.getProperty("os.arch");
	}
	
	public static String getOsName(){
		String osName=System.getProperty("os.name");
		osName=osName.replace(" ","");
		osName=osName.toLowerCase();
		if(osName.startsWith("windows")){
			osName="windows"; //Treat all Windows versions the same for now
		}
		logger.finest("\nSystemSetting --OS-" +osName);
		return osName;
	}
	
	public static void loadLibCurl(){
		System.loadLibrary(SystemSettings.getWFDB_NATIVE_BIN()+
				getWFDB_NATIVE_BIN()+ getfileSeparator() + "lib");
		logger.finest("\nSystemSetting --loadingLibCurl at: " +
				SystemSettings.getWFDB_NATIVE_BIN()+
				getWFDB_NATIVE_BIN()+ getfileSeparator() + "lib");
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
			LD_PATH=LD_PATH+tmp;
		}
		logger.finest("\nSystemSetting --Configuring PATH to: " + LD_PATH);
		env.put(OsPathName,LD_PATH);
		return LD_PATH;
	}
	
	public static String getWFDB_JAVA_HOME(){
		String packageDir = null;
		packageDir=Wfdbexec.class.getProtectionDomain().getCodeSource().getLocation().toString();
		int tmp = packageDir.lastIndexOf(getfileSeparator());
		packageDir=packageDir.substring(0,tmp+1);
		packageDir=packageDir.replace("file:","");
		logger.finest("\nSystemSetting --WFDB HOME: " + packageDir);
		return packageDir.toString();
	}
	
	public synchronized static String getWFDB_NATIVE_BIN() {
		String WFDB_NATIVE_BIN;
		String WFDB_JAVA_HOME=getWFDB_JAVA_HOME();
		//Set path to executables based on system/arch
		WFDB_NATIVE_BIN= WFDB_JAVA_HOME + "nativelibs" + getfileSeparator() + 
				getOsName().toLowerCase() + "-" + getosArch().toLowerCase() 
				+ getfileSeparator() ;
		logger.finest("\nSystemSetting --WFDB NATIVE BIN: " + WFDB_NATIVE_BIN);
		return WFDB_NATIVE_BIN;
	}

}
