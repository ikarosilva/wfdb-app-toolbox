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

#Package names and versions
CURL=curl-7.33.0
WFDB="wfdb-10.5.21"
ECGPUWAVE=ecgpuwave-1.3.2
PCKG_DIR="../wfdb-app-toolbox/mcode/nativelibs/linux-amd64"
#TODO: Make OS dependent
INSTALL_DIR:=$(shell pwd)
BUILD_DIR=build

clean: clean-wfdb clean-curl clean-edr clean-ecgpuwave
	rm -rf ./tmp; \
	rm -rf ./$(BUILD_DIR)
tmp:
	mkdir -p ./tmp/
build: 
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
edr: LC:=$(shell $(INSTALL_DIR)/$(BUILD_DIR)/bin/curl-config --cflags)
edr: LL=$(INSTALL_DIR)/$(BUILD_DIR)
edr: edr.c wfdb.isbuilt
	gcc $(LC)/curl -o edr -O edr.c -L$(LL)/lib -L$(LL)/lib64 -lm -lwfdb -lcurl
	cp edr ./$(BUILD_DIR)/bin;
edr.c:
	wget http://www.physionet.org/physiotools/edr/edr.c


#ECGPU Wave Target
clean-ecgpuwave: 
	rm -rf ./tmp/$(WFDB)
	rm -f ./ecgpuwave.isconfig; \
	rm -f ./ecgpuwave.isbuilt; \
	rm -f ecgpuwave.tar.gz
ecgpuwave.tar.gz:
	wget http://www.physionet.org/physiotools/ecgpuwave/src/$(ECGPUWAVE).tar.gz ;\
	mv $(ECGPUWAVE).tar.gz ecgpuwave.tar.gz
	cp ecgpuwave.tar.gz ./tmp/ecgpuwave.tar.gz;
	cd ./tmp; \
	tar xvfz ecgpuwave.tar.gz
ecgpuwave.isbuilt: C_INCLUDE_PATH:=/usr/include/$(shell gcc -print-multiarch)
ecgpuwave.isbuilt: LIBRARY_PATH:=$(INSTALL_DIR)/$(BUILD_DIR)/lib64 
ecgpuwave.isbuilt: ecgpuwave.tar.gz
	cd ./tmp/$(ECGPUWAVE);\
	export LIBRARY_PATH ;\
	make \
	&& touch ../../ecgpuwave.isbuilt
ecgpuwave: ecgpuwave.isbuilt wfdb

all: tmp build curl wfdb edr

checkin:
	rm -fv $(INSTALL_DIR)/$(BUILD_DIR)/bin/hr* ;\
	rm -fv $(INSTALL_DIR)/$(BUILD_DIR)/bin/pschart ;\
	rm -fv $(INSTALL_DIR)/$(BUILD_DIR)/bin/psdf ;\
	rm -fv $(INSTALL_DIR)/$(BUILD_DIR)/lib/pkgconfig/libcurl.pc ;\
	rm -fv $(PCKG_DIR)/bin/* ;\
	rm -rfv $(PCKG_DIR)/lib/* ;\ 
	rm -fv $(PCKG_DIR)/lib64/* ;\
	cp -rv $(INSTALL_DIR)/$(BUILD_DIR)/bin/* $(PCKG_DIR)/bin/ ;\
	cp -rv $(INSTALL_DIR)/$(BUILD_DIR)/lib/* $(PCKG_DIR)/lib/ ;\ 
	cp -rv $(INSTALL_DIR)/$(BUILD_DIR)/lib64/* $(PCKG_DIR)/lib64/ ;\
	
	
	
#TODO: Remove any files to reference to user name
#gcc -I/home/ikaro/workspace/wfdb/build/include/curl  edr.c -o edr -L/home/ikaro/workspace/wfdb/build/lib64 -L/home/ikaro/workspace/wfdb/build/lib -lwfdb  -lm -lcurl