#
# very basic Makefile for wfdb-swig-matlab
#
# NOTE: WSM is an abbreviation for wfdb-swig-matlab
#
# FIXME: instead of using the _CLASS variables, we are using *.class,
#        because javac will create files for inner classes and anonymous
#        classes that are hard to track dynamically. but this is rather
#        unsafe, so we should try to do better.
#
# FIXME: this is starting to get messy; should clean it up soon
#


#
#
#
OS = $(shell uname)


#
#
#
JAVAC = javac
JAR = $(shell which jar || which gjar || which fastjar)
TARGET = 1.5
WFDB_TARGET = 1.4

# FIXME: how to trigger an error if none of the cases below matches?
WFDB_JAR = ""
CLASSPATH = ""
WFDB_CLASSPATH = ""

ifeq ($(OS), Linux)

  WFDB_JAR = wfdb.jar
  CLASSPATH = $(WFDB_JAR):.
  WFDB_CLASSPATH = $(WFDB_JAR):wfdb-java1.4

endif

ifeq ($(OS), CYGWIN_NT-5.1)

  WFDB_JAR = wfdb.jar
  CLASSPATH = "$(WFDB_JAR);."
  WFDB_CLASSPATH = "$(WFDB_JAR);wfdb-java1.4"

endif

ifeq ($(OS), Darwin)

  WFDB_JAR = wfdb.jar
  CLASSPATH = $(WFDB_JAR):.
  WFDB_CLASSPATH = $(WFDB_JAR):wfdb-java1.4

endif


#
#
#
WSM_JAVA_FILES = wfdb-java1.4/Annotation.java \
                 wfdb-java1.4/LoadWFDBJava.java \
                 wfdb-java1.4/rdannMatlab.java \
                 wfdb-java1.4/rdsampMatlab.java \
                 wfdb-java1.4/skeweditMatlab.java \
                 wfdb-java1.4/time2secMatlab.java \
                 wfdb-java1.4/wfdbdescMatlab.java \
                 wfdb-java1.4/wfdbwhichMatlab.java \
                 wfdb-java1.4/wrannMatlab.java \
                 wfdb-java1.4/wrsampMatlab.java

WSM_LINUX_JAVA_FILES   = wfdb-java1.4/linux/NativeLibLoader.java

WSM_MACOSX_JAVA_FILES  = wfdb-java1.4/macosx/NativeLibLoader.java

WSM_WINDOWS_JAVA_FILES = wfdb-java1.4/windows/NativeLibLoader.java

WSM_INSTALLER = mcode/wfdb_install.m 
MATLAB_FILES = mcode/demo_wfdb_tools.m \
               mcode/Contents.m \
               mcode/wfdb_install.m \
               mcode/wfdb.m \
               mcode/rdann.m \
               mcode/rdsamp.m \
               mcode/rdsamp_stream.m \
               mcode/setwfdb.m \
               mcode/test_wfdb.m \
               mcode/time2sec.m \
               mcode/wfdb_config.m \
               mcode/wfdbdesc.m \
               mcode/wfdbwhich.m \
               mcode/wrann.m \
               mcode/wrsamp.m \
               mcode/mat2wfdb.m \
               mcode/wfdb_license.m \
               mcode/wfdb_query.m \
               \
               mcode/util/catfield.m \
               mcode/util/deepconvert.m \
               mcode/util/struct2javaarray.m \
               mcode/util/varargin2struct.m \
               mcode/util/verify_params.m


#
# a list of all the matlab code files (i.e. $(MATLAB_FILES))
# FIXME: subdirs won't work properly across all systems!!!
#
MATLAB_FILES_LIST = mcode/matlab-files.txt


#
#
#
SOURCE_TARBALL = wfdb-swig-matlab.tar.gz
SOURCE_TARBALL_SRC_FILES = $(WSM_JAVA_FILES) \
                           $(WSM_LINUX_JAVA_FILES) \
                           $(WSM_MACOSX_JAVA_FILES) \
                           $(WSM_WINDOWS_JAVA_FILES) \
                           $(MATLAB_FILES) \
                           aux/build_wfdbjava.sh \
                           aux/wfdb-10.4.18.patch \
                           aux/withtty.c \
                           aux/withtty-mac.c \
                           nativelibs/linux-amd64/native-lib-files-amd64.txt \
                           nativelibs/linux-amd64/withtty-amd64-name.txt \
                           nativelibs/linux-i386/native-lib-files-i386.txt \
                           nativelibs/linux-i386/withtty-i386-name.txt \
                           nativelibs/macosx-i386/native-lib-files-i386.txt \
                           nativelibs/macosx-i386/withtty-i386-name.txt \
                           nativelibs/macosx-ppc/native-lib-files-ppc.txt \
                           nativelibs/macosx-ppc/withtty-ppc-name.txt \
                           nativelibs/windows-amd64/native-lib-files-amd64.txt \
                           nativelibs/windows-x86/native-lib-files-x86.txt \
                           Makefile \
                           README.build


#
#
#
WSM_CLASS_FILES         = $(WSM_JAVA_FILES:%.java=%.class)
WSM_LINUX_CLASS_FILES   = $(WSM_LINUX_JAVA_FILES:%.java=%.class)
WSM_MACOSX_CLASS_FILES  = $(WSM_MACOSX_JAVA_FILES:%.java=%.class)
WSM_WINDOWS_CLASS_FILES = $(WSM_WINDOWS_JAVA_FILES:%.java=%.class)

#
# this is a bit confusing: wfdb-swig-matlab.jar contains wsm-classes.jar;
# wsm-classes.jar is what gets copied locally. we do this to avoid copying
# a bunch of class files (and to avoid those class files being loaded
# by the JVM during installation, which is not at all what we want).
#
# FIXME: the names of these two jars could be much better.
#
WSM_CLASSES_JAR = wsm-classes.jar

WSM_LINUX_JAR = wfdb-swig-matlab-linux.jar
WSM_LINUX_JAR_UNSIGNED = $(WSM_LINUX_JAR)-unsigned
WSM_MACOSX_JAR = wfdb-swig-matlab-macosx.jar
WSM_MACOSX_JAR_UNSIGNED = $(WSM_MACOSX_JAR)-unsigned
WSM_WINDOWS_JAR = wfdb-swig-matlab-windows.jar
WSM_WINDOWS_JAR_UNSIGNED = $(WSM_WINDOWS_JAR)-unsigned

WSM_NATIVE_JARS = $(WSM_LINUX_JAR) \
                       $(WSM_MACOSX_JAR) \
                       $(WSM_WINDOWS_JAR) 
                       
WFDB_NATIVELIBS_WINDOWS_AMD64_JAR = wfdb-nativelibs-windows-amd64.jar
WFDB_NATIVELIBS_WINDOWS_X86_JAR   = wfdb-nativelibs-windows-x86.jar
WFDB_NATIVELIBS_LINUX_AMD64_JAR   = wfdb-nativelibs-linux-amd64.jar
WFDB_NATIVELIBS_LINUX_I386_JAR    = wfdb-nativelibs-linux-i386.jar
WFDB_NATIVELIBS_MACOSX_I386_JAR   = wfdb-nativelibs-macosx-i386.jar
WFDB_NATIVELIBS_MACOSX_X86_64_JAR = wfdb-nativelibs-macosx-x86_64.jar
WFDB_NATIVELIBS_MACOSX_PPC_JAR    = wfdb-nativelibs-macosx-ppc.jar

WFDB_NATIVELIBS_JARS = $(WFDB_NATIVELIBS_WINDOWS_AMD64_JAR) \
                       $(WFDB_NATIVELIBS_WINDOWS_X86_JAR) \
                       $(WFDB_NATIVELIBS_LINUX_AMD64_JAR) \
                       $(WFDB_NATIVELIBS_LINUX_I386_JAR) \
                       $(WFDB_NATIVELIBS_MACOSX_I386_JAR) \
                       $(WFDB_NATIVELIBS_MACOSX_X86_64_JAR) \
                       $(WFDB_NATIVELIBS_MACOSX_PPC_JAR)

WEBSTART_COMMON_JAR = wsm-installer-common.jar
WEBSTART_LINUX_JAR = wsm-installer-linux.jar
WEBSTART_MACOSX_JAR = wsm-installer-macosx.jar
WEBSTART_WINDOWS_JAR = wsm-installer-windows.jar

WEBSTART_JARS = $(WEBSTART_COMMON_JAR) \
                $(WEBSTART_LINUX_JAR) \
                $(WEBSTART_MACOSX_JAR) \
                $(WEBSTART_WINDOWS_JAR)

WEBSTART_JARS_UNSIGNED = $(WEBSTART_JARS:%.jar=%.jar-unsigned)

MATLAB_FILES_JAR = wsm-matlab-code.jar
MATLAB_FILES_MANIFEST_ADDITION = wsm-matlab-code-Manifest.txt
MATLAB_FILES_JAR_UNSIGNED = $(MATLAB_FILES_JAR)-unsigned

#Target for MATLAB based installation
WFDB_MATLAB_TOOLBOX= WFDB_Toolbx_0_0_3.zip

#
#
#
all: wfdb-swig-matlab $(SOURCE_TARBALL)

#
#
#
wfdb-swig-matlab: $(WSM_LINUX_JAR) $(WSM_MACOSX_JAR) $(WSM_WINDOWS_JAR) $(MATLAB_FILES_JAR) wfdb-nativelibs-jars

wfdb-nativelibs-jars: $(WFDB_NATIVELIBS_JARS)

$(WSM_LINUX_JAR): $(WSM_CLASS_FILES) $(WSM_LINUX_CLASS_FILES)
	cd wfdb-java1.4; cp linux/*.class ./; $(JAR) cvf ../$(WSM_CLASSES_JAR) *.class; cd ..
	$(JAR) cvf $(WSM_LINUX_JAR_UNSIGNED) $(WSM_CLASSES_JAR)
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WSM_LINUX_JAR) $(WSM_LINUX_JAR_UNSIGNED) helloAlias
	rm $(WSM_LINUX_JAR_UNSIGNED)

$(WSM_MACOSX_JAR): $(WSM_CLASS_FILES) $(WSM_MACOSX_CLASS_FILES)
	cd wfdb-java1.4; cp macosx/*.class ./; $(JAR) cvf ../$(WSM_CLASSES_JAR) *.class; cd ..
	$(JAR) cvf $(WSM_MACOSX_JAR_UNSIGNED) $(WSM_CLASSES_JAR)
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WSM_MACOSX_JAR) $(WSM_MACOSX_JAR_UNSIGNED) helloAlias
	rm $(WSM_MACOSX_JAR_UNSIGNED)

$(WSM_WINDOWS_JAR): $(WSM_CLASS_FILES) $(WSM_WINDOWS_CLASS_FILES)
	cd wfdb-java1.4; cp windows/*.class ./; $(JAR) cvf ../$(WSM_CLASSES_JAR) *.class; cd ..
	$(JAR) cvf $(WSM_WINDOWS_JAR_UNSIGNED) $(WSM_CLASSES_JAR)
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WSM_WINDOWS_JAR) $(WSM_WINDOWS_JAR_UNSIGNED) helloAlias
	rm $(WSM_WINDOWS_JAR_UNSIGNED)

# FIXME: `cat native-lib-files.txt` won't work for filenames with whitespace
$(WFDB_NATIVELIBS_WINDOWS_AMD64_JAR):
	cd nativelibs/windows-amd64; $(JAR) cvf ../../$(WFDB_NATIVELIBS_WINDOWS_AMD64_JAR)-unsigned `cat native-lib-files-amd64.txt` native-lib-files-amd64.txt; cd ../..
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WFDB_NATIVELIBS_WINDOWS_AMD64_JAR) $(WFDB_NATIVELIBS_WINDOWS_AMD64_JAR)-unsigned helloAlias
	rm $(WFDB_NATIVELIBS_WINDOWS_AMD64_JAR)-unsigned

# FIXME: `cat native-lib-files.txt` won't work for filenames with whitespace
$(WFDB_NATIVELIBS_WINDOWS_X86_JAR):
	cd nativelibs/windows-x86; $(JAR) cvf ../../$(WFDB_NATIVELIBS_WINDOWS_X86_JAR)-unsigned `cat native-lib-files-x86.txt` native-lib-files-x86.txt; cd ../..
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WFDB_NATIVELIBS_WINDOWS_X86_JAR) $(WFDB_NATIVELIBS_WINDOWS_X86_JAR)-unsigned helloAlias
	rm $(WFDB_NATIVELIBS_WINDOWS_X86_JAR)-unsigned

# FIXME: `cat native-lib-files.txt` won't work for filenames with whitespace
# FIXME: we are stuffing withtty-name.txt into this jar as well -- the name "nativelibs" is
#        thus quite watered down
$(WFDB_NATIVELIBS_LINUX_AMD64_JAR):
	cd nativelibs/linux-amd64; $(JAR) cvf ../../$(WFDB_NATIVELIBS_LINUX_AMD64_JAR)-unsigned `cat native-lib-files-amd64.txt` native-lib-files-amd64.txt `cat withtty-amd64-name.txt` withtty-amd64-name.txt; cd ../..
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WFDB_NATIVELIBS_LINUX_AMD64_JAR) $(WFDB_NATIVELIBS_LINUX_AMD64_JAR)-unsigned helloAlias
	rm $(WFDB_NATIVELIBS_LINUX_AMD64_JAR)-unsigned

# FIXME: `cat native-lib-files.txt` won't work for filenames with whitespace
# FIXME: we are stuffing withtty-name.txt into this jar as well -- the name "nativelibs" is
#        thus quite watered down
$(WFDB_NATIVELIBS_LINUX_I386_JAR):
	cd nativelibs/linux-i386; $(JAR) cvf ../../$(WFDB_NATIVELIBS_LINUX_I386_JAR)-unsigned `cat native-lib-files-i386.txt` native-lib-files-i386.txt `cat withtty-i386-name.txt` withtty-i386-name.txt; cd ../..
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WFDB_NATIVELIBS_LINUX_I386_JAR) $(WFDB_NATIVELIBS_LINUX_I386_JAR)-unsigned helloAlias
	rm $(WFDB_NATIVELIBS_LINUX_I386_JAR)-unsigned

# FIXME: `cat native-lib-files.txt` won't work for filenames with whitespace
# FIXME: we are stuffing withtty-name.txt into this jar as well -- the name "nativelibs" is
#        thus quite watered down
$(WFDB_NATIVELIBS_MACOSX_I386_JAR):
	cd nativelibs/macosx-i386; $(JAR) cvf ../../$(WFDB_NATIVELIBS_MACOSX_I386_JAR)-unsigned `cat native-lib-files-i386.txt` native-lib-files-i386.txt `cat withtty-i386-name.txt` withtty-i386-name.txt; cd ../..
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WFDB_NATIVELIBS_MACOSX_I386_JAR) $(WFDB_NATIVELIBS_MACOSX_I386_JAR)-unsigned helloAlias
	rm $(WFDB_NATIVELIBS_MACOSX_I386_JAR)-unsigned

# FIXME: `cat native-lib-files.txt` won't work for filenames with whitespace
# FIXME: we are stuffing withtty-name.txt into this jar as well -- the name "nativelibs" is
#        thus quite watered down
$(WFDB_NATIVELIBS_MACOSX_X86_64_JAR):
	cd nativelibs/macosx-x86_64; $(JAR) cvf ../../$(WFDB_NATIVELIBS_MACOSX_X86_64_JAR)-unsigned `cat native-lib-files-x86_64.txt` native-lib-files-x86_64.txt `cat withtty-x86_64-name.txt` withtty-x86_64-name.txt; cd ../..
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WFDB_NATIVELIBS_MACOSX_X86_64_JAR) $(WFDB_NATIVELIBS_MACOSX_X86_64_JAR)-unsigned helloAlias
	rm $(WFDB_NATIVELIBS_MACOSX_X86_64_JAR)-unsigned

# FIXME: `cat native-lib-files.txt` won't work for filenames with whitespace
# FIXME: we are stuffing withtty-name.txt into this jar as well -- the name "nativelibs" is
#        thus quite watered down
$(WFDB_NATIVELIBS_MACOSX_PPC_JAR):
	cd nativelibs/macosx-ppc; $(JAR) cvf ../../$(WFDB_NATIVELIBS_MACOSX_PPC_JAR)-unsigned `cat native-lib-files-ppc.txt` native-lib-files-ppc.txt `cat withtty-ppc-name.txt` withtty-ppc-name.txt; cd ../..
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(WFDB_NATIVELIBS_MACOSX_PPC_JAR) $(WFDB_NATIVELIBS_MACOSX_PPC_JAR)-unsigned helloAlias
	rm $(WFDB_NATIVELIBS_MACOSX_PPC_JAR)-unsigned

$(MATLAB_FILES_JAR): $(MATLAB_FILES) $(MATLAB_FILES_LIST) $(MATLAB_FILES_MANIFEST_ADDITION) 
	$(JAR) cvfm $(MATLAB_FILES_JAR_UNSIGNED) $(MATLAB_FILES_MANIFEST_ADDITION) $(MATLAB_FILES) $(MATLAB_FILES_LIST)
	jarsigner -keystore debug_keystore -storepass mypass -signedjar $(MATLAB_FILES_JAR) $(MATLAB_FILES_JAR_UNSIGNED) helloAlias
	rm $(MATLAB_FILES_JAR_UNSIGNED)

$(MATLAB_FILES_LIST): $(MATLAB_FILES)
	echo $(MATLAB_FILES) > $(MATLAB_FILES_LIST)
	
$(WFDB_MATLAB_TOOLBOX): $(MATLAB_FILES_JAR)  $(WFDB_NATIVELIBS_JARS) $(WSM_NATIVE_JARS) wfdb-swig.jar $(WSM_INSTALLER) README.txt 
	zip -r -j $(WFDB_MATLAB_TOOLBOX) $(MATLAB_FILES_JAR)  $(WFDB_NATIVELIBS_JARS) $(WSM_NATIVE_JARS) wfdb-swig.jar $(WSM_INSTALLER) README.txt
# 
#
#
CWD = $(shell basename $(shell pwd))
$(SOURCE_TARBALL): $(SOURCE_TARBALL_SRC_FILES)
	cd ..; tar cvfz $(CWD)/$(SOURCE_TARBALL) $(foreach f, $(SOURCE_TARBALL_SRC_FILES), $(CWD)/$(f)); cd $(CWD)


#
# FIXME: the line for removing *.class files is really bad...
# FIXME: update this
#
clean:
	rm -f $(WSM_CLASS_FILES) $(WEBSTART_CLASS_FILES) \
         $(WSM_JAR) $(WSM_CLASSES_JAR) \
         $(WEBSTART_JARS) $(WEBSTART_JARS_UNSIGNED) \
         $(MATLAB_FILES_JAR) $(MATLAB_FILES_LIST) \
         $(WSM_JAR_UNSIGNED) $(MATLAB_FILES_JAR_UNSIGNED) \
         wfdb-java1.4/*.class \
         wfdb.jar \
         $(SOURCE_TARBALL) \
         ./*~ ./*/*~

#
#
#
rebuild: clean all

#
#
#
wfdb-java1.4/%.class: wfdb-java1.4/%.java wfdb.jar
	javac -source $(WFDB_TARGET) -target $(WFDB_TARGET) -cp $(WFDB_CLASSPATH) $<

#
# FIXME: for -target 1.5, use the 1.5 wfdb.jar
#
%.class: %.java wfdb.jar
	javac -source $(TARGET) -target $(TARGET) -cp $(CLASSPATH) $<
#
#
#
wfdb.jar: wfdb-swig.jar
	$(JAR) xvf wfdb-swig.jar

