# Define a variable for classpath
CLASS_PATH = ../../bin

# Define a virtual path for .class in the bin directory
vpath %.class $(CLASS_PATH)

all : test

test: librdsampjni.so
	LD_LIBRARY_PATH=. java -classpath $(CLASS_PATH) org.physionet.wfdb.jni.Rdsamp

librdsampjni.so : rdsampjni.o
	gcc -W -fPIC -I"$(JAVA_HOME)/include/" -I"$(JAVA_HOME)/include/linux" \
	-shared -o librdsampjni.so rdsampjni.c

rdsampjni.o : rdsampjni.c org_physionet_wfdb_jni_Rdsamp.h
	gcc -I"$(JAVA_HOME)/include" -I"$(JAVA_HOME)/include/linux" -c $< -o $@

#The WFDB Project needs to be built in order to generate
#the Java classes in ../../bin/org/physionet/wfdb directories for this target
org_physionet_wfdb_jni_Rdsamp.h : 
	javah -classpath $(CLASS_PATH) org.physionet.wfdb.jni.Rdsamp 

clean :
	rm -vf org_physionet_wfdb_jni_Rdsamp.h *.o *.so