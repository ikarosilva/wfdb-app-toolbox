#Makefile fetching binaries required by the wfdb-application-toolbox

#The compilation of these binaries are outside the scope of the 
#toolbox project. The project expects the most updated binaries to be 
#located at PhysioNet and fetch it from there. 
#
#http://www.physionet.org/physiotools/binaries/
#
#In some platforms, it maybe required to create symlinks:
#
#ln -s libwfdb.so.10.5 libwfdb.so.10
#ln -s libwfdb.so.10.5 libwfdb.so

#Note: the user should *NOT* run this make. This is intended for development 
#and deployment only. 



LINUX32_BIN_PATH = "http://www.physionet.org/physiotools/binaries/intel-linux/wfdb-10.5.8-i686-Linux/usr/bin/"
LINUX32_LIB_PATH = "http://www.physionet.org/physiotools/binaries/intel-linux/wfdb-10.5.8-i686-Linux/usr/lib/"


#To be run from nativelibs directory!
wfdb-windows:
	cd windows-amd64; \
	wget -r -np http://www.physionet.org/physiotools/binaries/windows/wfdb-MINGW/opt/wfdb/bin/; \
	mv www.physionet.org/physiotools/binaries/windows/wfdb-MINGW/opt/wfdb/bin/* .; \
	rm -rf www.physionet.org/; \
	rm index.html*; \
	cd ..