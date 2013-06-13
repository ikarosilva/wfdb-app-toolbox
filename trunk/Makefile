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
EQUINOXPATH := $(ECLIPSEPATH)org.eclipse.equinox.launcher_1.3.0.v20120522-1813.jar
JARFLAGS := -jar		\
		  $(EQUINOXPATH)		\
		  -application $(ANTPATH)	\
		  -buildfile $(BUILDFILE)
APP_NAME="wfdb-app-toolbox-0-0-1.zip"

#Always check that this matches with Ant's script (jarbuild.xml)
JAR6_NAME="wfdb-app-JVM6-0-0-2.jar" 
JAR7_NAME="wfdb-app-JVM7-0-0-2.jar"
	
#TODO: There are two directories for linux. we need to remove one!	
clean: 
	rm -rf ./mcode/example/*~ \
	       ./mcode/example/*.wqrs \
	      ./mcode/*~ \
	
	
package: clean jartest
	zip -vr $(APP_NAME) mcode -x@zipexclude.lst  
	
%.java:
	java $(JARFLAGS) jar6; \
	java $(JARFLAGS) jar7

$(JAR6_NAME): %.java
	
$(JAR7_NAME): %.java
	
jar: $(JAR6_NAME) $(JAR7_NAME)

jartest: $(JAR6_NAME) $(JAR7_NAME)
	cd mcode; \
	java -cp $(JAR6_NAME) org.physionet.wfdb.Wfdbexec rdsamp -r mitdb/100 -t s5; \
	java -cp $(JAR7_NAME) org.physionet.wfdb.Wfdbexec rdsamp -r mitdb/100 -t s5
	
	
	