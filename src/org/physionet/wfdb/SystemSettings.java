package org.physionet.wfdb;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.Map;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

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
            // No RPATH on windows, so library dependencies can't
            // be loaded automatically and must be pre-loaded.

            // (Although Windows automatically searches for
            // required DLLs in the *application's* directory, it
            // doesn't do the same when loading a DLL.)

            // Nasty kludge: list the required libraries in a
            // separate text file, so they do not have to be
            // hardcoded here.

            String libdir = getWFDB_NATIVE_BIN(customArch) + "bin\\";
            String depfile = libdir + "lib" + libName + ".dep";
            try {
                BufferedReader r = new BufferedReader(new FileReader(depfile));
                String name;
                while ((name = r.readLine()) != null) {
                    System.load(libdir + name);
                }
            } catch (IOException e) {
                throw new UnsatisfiedLinkError("error reading " + depfile);
            }
            System.load(libdir + "lib" + libName + ".dll");
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
