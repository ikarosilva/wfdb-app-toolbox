#Makefile for wfdb-application-toolbox 
#
# Written by Ikaro Silva, 2013
#
#For now simple make file for packaging and deploying application.
#Requires that the Java classes be compiled into runnable JARs.
#
#To compile the Toolbox for deployment run:
#make package

#

#TODO: Automate the process of compiling the Java classes into runnable
#JARs by calling Eclipse and Ant in the makefile

BUILDFILE := ./jarbuild.xml
ECLIPSEPATH := /lib64/eclipse/plugins/
ANTPATH := org.eclipse.ant.core.antRunner
#EQUINOXPATH := $(ECLIPSEPATH)org.eclipse.equinox.launcher_1.3.0.v20120522-1813.jar
EQUINOXPATH := ~/Downloads/adt-bundle-linux-x86_64-20130729/eclipse/plugins/org.eclipse.equinox.launcher_1.3.0.v20120522-1813.jar
JARFLAGS := -jar		\
		  $(EQUINOXPATH)		\
		  -application $(ANTPATH)	\
		  -buildfile $(BUILDFILE)

#Always check that this matches with Ant's script (jarbuild.xml),
#with the loading function wfdbloadlib.m , and with Contents.m
#There is really no reason by the *.jar and *.zip should need to have the same
#version numbers, as they are really modular...But for now we keep them at the same
#versioning level in order to avoid (or increase?) confusion.
APP_NAME="wfdb-app-toolbox-0-9-5.zip"
JAR6_NAME="wfdb-app-JVM6-0-9-5.jar" 
JAR7_NAME="wfdb-app-JVM7-0-9-5.jar"

#TODO: There are two directories for linux. we need to remove one!	
clean: 
	rm -rf ./mcode/example/*~ \
	       ./mcode/example/*.wqrs \
	      ./mcode/*~ \
	
	
package: clean jartest unit-test.zip
	zip -r $(APP_NAME) mcode -x@zipexclude.lst  
	
%.java:
	java $(JARFLAGS) jar6; \
	java $(JARFLAGS) jar7

$(JAR6_NAME): %.java
	
$(JAR7_NAME): %.java
	
jar: $(JAR6_NAME) $(JAR7_NAME)

unit-test.zip:
	zip -r $@ UnitTests -x@zipexclude.lst

jartest: $(JAR6_NAME) $(JAR7_NAME) unit-test.zip
	cd mcode; \
	java -cp $(JAR6_NAME) org.physionet.wfdb.Wfdbexec rdsamp -r mitdb/100 -t s5; \
	java -cp $(JAR7_NAME) org.physionet.wfdb.Wfdbexec rdsamp -r mitdb/100 -t s5
	
	
	