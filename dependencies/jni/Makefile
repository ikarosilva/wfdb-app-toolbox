#
#
# Before running this Makefile:
#
# 1) The WFDB Project needs to be built in order to generate
#    the Java classes in ../../bin/org/physionet/wfdb directories for the  
#    org_physionet_wfdb_jni_Rdsamp.h target.
#
# 2) The WFDB_INCLUDE variable needs to be configure so that wfdb/wfdb.h
#    can be found by the compiler
#
# 3) The WFDB_LIB variable needs to be configured in order for th testing 
#    to work properly.
#
#

# Define a variable for class path
CLASS_PATH = ../../bin
#Denife location of wfdb/wfdb.h
WFDB_INCLUDE=/home/ikaro/Downloads/
WFDB_LIB =../../mcode/nativelibs/linux/lib64/
# Define a virtual path for .class in the bin directory
vpath %.class $(CLASS_PATH)

all : test

test: librdsampjni.so
	LD_LIBRARY_PATH=".:$(WFDB_LIB)" java -classpath $(CLASS_PATH) org.physionet.wfdb.jni.Rdsamp

librdsampjni.so : rdsampjni.o
	gcc -W -fPIC -I"$(JAVA_HOME)/include/" -I"$(JAVA_HOME)/include/linux" \
	-I"$(WFDB_INCLUDE)" "-L$(WFDB_LIB)" -shared -o librdsampjni.so rdsampjni.c -lwfdb

rdsampjni.o : rdsampjni.c org_physionet_wfdb_jni_Rdsamp.h
	gcc -I"$(JAVA_HOME)/include" -I"$(JAVA_HOME)/include/linux" \
	-I"$(WFDB_INCLUDE)" -c $< -o $@


org_physionet_wfdb_jni_Rdsamp.h : 
	javah -classpath $(CLASS_PATH) org.physionet.wfdb.jni.Rdsamp 

clean :
	rm -vf org_physionet_wfdb_jni_Rdsamp.h *.o *.so