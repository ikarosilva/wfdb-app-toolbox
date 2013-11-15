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

#TODO: Make OS dependent
CURL=curl-7.33.0
WFDB="wfdb-10.5.20"
INSTALL_DIR:=$(shell pwd)
BUILD_DIR=build

clean: clean-wfdb clean-curl clean-edr
	rm -rf ./tmp; \
	rm -rf ./$(BUILD_DIR)
tmp:
	mkdir -p ./tmp/
build: tmp
	rm -rf ./$(BUILD_DIR)/; \
	mkdir ./$(BUILD_DIR);

##CURL TARGET
#TODO: Remove from build dir ??
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
	./configure --prefix=$(INSTALL_DIR)/$(BUILD_DIR) --without-ssl --without-zlib --without-libssh2 --disable-ldap; \
	touch ../../curl.isconfig
curl.isbuilt: curl.isconfig
	cd ./tmp/$(CURL); \
	make ;\
	make install \
	&& touch ../../curl.isbuilt;
curl: curl.isbuilt

##WFDB TARGET
#TODO: remove for build directory as well??
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
	./configure --prefix=$(INSTALL_DIR)/$(BUILD_DIR) --with-libcurl \
	&& touch ../../wfdb.isconfig
wfdb.isbuilt: curl.isbuilt wfdb.isconfig
	cd ./tmp/;\
	export LIBRARY_PATH=$(INSTALL_DIR)/$(BUILD_DIR)/lib ;\
	cd ./$(WFDB)/ ;\
	export PATH=$(PATH):$(INSTALL_DIR)/$(BUILD_DIR)/bin; \
	make ;\
	make install \
	&& touch ../../wfdb.isbuilt
wfdb: wfdb.isbuilt

##EDR TARGET
#TODO: clean build folder as well??
clean-edr:
	rm -f edr*; \
	rm -f ./$(BUILD_DIR)/edr;
edr: edr.c wfdb.isbuilt
	gcc -o edr -O edr.c -lm -lwfdb ;\
	cp edr ./$(BUILD_DIR)/bin;
edr.c:
	wget http://www.physionet.org/physiotools/edr/edr.c


#TODO: Remove any files to reference to user name
