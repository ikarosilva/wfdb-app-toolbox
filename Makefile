#Makefile for wfdb-application-toolbox 
#
# Written by Ikaro Silva, 2013
#
#For now simple make file for packaging and deploying application.
#Requires that the Java classes be compiled into runnable JARs.
#
#To compile the Toolbox for deployment run:
#make package

BUILDFILE := ./jarbuild.xml
ANT = ant

#Always check that this matches with Ant's script (jarbuild.xml),
#with the loading function wfdbloadlib.m , and with Contents.m
#There is really no reason why the *.jar and *.zip should need to have the same
#version numbers, as they are really modular...But for now we keep them at the same
#versioning level in order to avoid (or increase?) confusion.
VERSION=0-10-0
APP_NAME=wfdb-app-toolbox-$(VERSION).zip
JAR7_NAME=wfdb-app-JVM7-$(VERSION).jar

javasrc=$(shell find src -name \*.java)

all: jar7 nativelibs

jar7: mcode/$(JAR7_NAME)
mcode/$(JAR7_NAME): $(javasrc) $(BUILDFILE)
	$(ANT) -f $(BUILDFILE) jar7

nativelibs: jar7
	cd mcode/nativelibs && $(MAKE) install
	set -e; if grep -q '^WFDB_CUSTOMLIB=0' mcode/wfdbloadlib.m; then \
	 sed 's/^WFDB_CUSTOMLIB=0/WFDB_CUSTOMLIB=1/' -i mcode/wfdbloadlib.m; \
	fi

clean:
	cd mcode/nativelibs && $(MAKE) clean
	rm -rf bin
	rm -f mcode/*.jar

#Target for HTML doc generation from M-files
doc:
	./gen-doc.sh

package: jar7 doc unit-test.zip
	rm -f $(APP_NAME)
	set -e; if grep -q '^WFDB_CUSTOMLIB=1' mcode/wfdbloadlib.m; then \
	 sed 's/^WFDB_CUSTOMLIB=1/WFDB_CUSTOMLIB=0/' -i mcode/wfdbloadlib.m; \
	fi
	zip -r $(APP_NAME) mcode -x@zipexclude.lst

unit-test.zip:
	zip -r $@ UnitTests -x@zipexclude.lst

check:
	set -e; unset DISPLAY; mcodedir=`pwd`/mcode; \
	cd UnitTests && octave -q --eval \
	 "pkg load signal; \
	  addpath('$$mcodedir'); \
	  confirm_recursive_rmdir(0); \
	  BatchTest"

jartest: mcode/$(JAR7_NAME) unit-test.zip
	cd mcode; \
	java -cp $(JAR7_NAME) org.physionet.wfdb.Wfdbexec rdsamp -r mitdb/100 -t s5
