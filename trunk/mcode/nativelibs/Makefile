#Makefile for downloading and building all of the native libraries to support WFDB;
#WFDB will be build on the current directory under the tmp subfolder

#This Makefile will build the following packages:
# curl 
# wfdb (with curl dependency)
# edr  (with wfdb dependency)
#
# The file will fetch the required files from their resepective sources and comp
# and compile everything accordingly. It may be necessary to run this file as 
# with root priveleges.
 
#The Makefile should be copied and run from a temporary directory. A 'bin' subdirectory will be 
#generate with the native binaries. This subdirectory can then be copied to the respective OS
#folder


#TODO: Make OS dependent
CURL=curl-7.33.0
WFDB="wfdb-10.5.20"
INSTALL_DIR:=$(shell pwd)

clean: clean-wfdb clean-curl clean-edr
	rm -rf ./tmp; \
	rm -rf ./bin
tmp:
	mkdir -p ./tmp/
bin: tmp
	rm -rf ./bin/; \
	mkdir ./bin

##CURL TARGET
clean-curl: 
	rm -rf ./tmp/$(CURL); \
	rm -f ./curl.isconfig; \
	rm -f ./curl.isbuilt; \
	rm -f curl.tar.gz
curl.tar.gz:
	wget http://curl.haxx.se/download/$(CURL).tar.gz; \
	mv $(CURL).tar.gz curl.tar.gz; \
	cp ./curl.tar.gz ./tmp/;
curl.isconfig: curl.tar.gz
	cd ./tmp/; \
	tar xfvz curl.tar.gz; \
	cd $(CURL); \
	./configure --without-ssl --without-zlib --without-libssh2 --disable-ldap; \
	touch ../../curl.isconfig
curl.isbuilt: curl.isconfig
	cd ./tmp/$(CURL); \
	chmod a+x curl-config;\
	make \
	&& touch ../../curl.isbuilt;\
	cp -l ./lib/.libs/libcurl.so* $(INSTALL_DIR)/bin/ 
curl: curl.isbuilt

##WFDB TARGET
clean-wfdb: 
	rm -rf ./tmp/$(WFDB)
	rm -f ./wfdb.isconfig; \
	rm -f ./wfdb.isbuilt; \
	rm -f wfdb.tar.gz
wfdb.tar.gz:
	wget http://www.physionet.org/physiotools/wfdb.tar.gz; \
	cp ./wfdb.tar.gz ./tmp/wfdb.tar.gz;
wfdb.isconfig: wfdb.tar.gz
	cd ./tmp; \
	tar xvfz wfdb.tar.gz; \
	cd $(WFDB); \
	./configure --prefix=$(INSTALL_DIR)/tmp --with-libcurl \
	&& touch ../../wfdb.isconfig
wfdb.isbuilt: curl.isbuilt wfdb.isconfig
	cd ./tmp/;\
	export LIBRARY_PATH=$(INSTALL_DIR)/tmp/$(CURL)/lib/.libs/ ;\
	cd ./$(WFDB)/ ;\
	cp -r ../$(CURL)/include/curl ./build/include/ ;\
	export PATH=$(PATH):$(INSTALL_DIR)/tmp/$(CURL); \
	make \
	&& touch ../../wfdb.isbuilt; \
	cp -r ./build/bin/* $(INSTALL_DIR)/bin/ ;\
	cp -r ./build/include/wfdb/* $(INSTALL_DIR)/bin/ ;\
	cp -rl ./build/lib64/* $(INSTALL_DIR)/bin/ 
wfdb: wfdb.isbuilt

##EDR TARGET
clean-edr:
	rm -f ./tmp/edr*; \
	rm -f edr*; \
	rm ./bin/edr;
edr: edr.c wfdb.isbuilt
	cd ./tmp; \
	export LIBRARY_PATH=$(INSTALL_DIR)/bin/ ;\
	export PATH=$(PATH):$(INSTALL_DIR)/tmp ;\
	gcc -o edr -O edr.c -lm -lwfdb \
	&& cp edr ../ ;\
	cp edr ../bin/;
edr.c:
	wget http://www.physionet.org/physiotools/edr/edr.c;\
	cp erd.c ./tmp

