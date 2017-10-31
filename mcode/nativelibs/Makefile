#Makefile for downloading and building all of the native libraries to support WFDB;
#WFDB will be build on the current directory under the tmp subfolder

#This Makefile will build the following packages:
# curl
# wfdb (with curl dependency)
# edr  (with wfdb dependency)
# ecgpuwave (with wfdb dependency)
# mse
# dfa
#
# The file will fetch the required files from their resepective sources
# and compile everything accordingly.

# Build configuration

# Target subdirectory
host=custom

#Package names and versions

CURL_PKG=curl-7.56.0
CURL_ARCHIVE=$(CURL_PKG).tar.gz
CURL_SOURCE=http://curl.haxx.se/download/$(CURL_ARCHIVE)
CURL_SHA256=f1bc17a7e5662dbd8d4029750a6dbdb72a55cf95826a270ab388b05075526104

WFDB_PKG=wfdb-10.5.25
#WFDB_ARCHIVE=$(WFDB_PKG).tar.gz
#WFDB_SOURCE=http://www.physionet.org/physiotools/archives/wfdb-10.5/$(WFDB_ARCHIVE)
WFDB_ARCHIVE=wfdb-10.5.25pre1.tar.gz
WFDB_SOURCE=http://www.physionet.org/physiotools/beta/$(WFDB_ARCHIVE)
WFDB_SHA256=37fb59c04f5b36d4146e3cb71d28a59108581271feb079631cd922febe21fa73
WFDB_MAJOR=10

ECGPUWAVE_PKG=ecgpuwave-1.3.3
ECGPUWAVE_ARCHIVE=$(ECGPUWAVE_PKG).tar.gz
ECGPUWAVE_SOURCE=http://www.physionet.org/physiotools/ecgpuwave/src/$(ECGPUWAVE_ARCHIVE)
ECGPUWAVE_SHA256=900ead3cc1495d0095f3fa8ca123bf695a73b4799108bf9a0b6b79feff79df54

EDR_SOURCE=http://www.physionet.org/physiotools/edr/edr-1.0.c
EDR_SHA256=c1a07750291c9c9172786e1d9c3b9d171bd198dfd27f4b5115ed1c890615c131

MSE_SOURCE=http://www.physionet.org/physiotools/mse/mse-1.0.c
MSE_SHA256=98b53053f2bbfa0fbd4522fa092a2be453eb6fb952ef5145834401c41b46bdea

DFA_SOURCE=http://www.physionet.org/physiotools/dfa/dfa-1.0.c
DFA_SHA256=37be78e9a9744c277b879b89046acb32ab9fb6e5f68b3a886e3c9bdf1a17d639

ifneq ($(crosshost),)
CC=$(crosshost)-gcc $(extra_ldflags)
F77=$(crosshost)-gfortran -std=legacy -ffixed-line-length-none -fno-automatic $(extra_ldflags)
INSTALL_NAME_TOOL=$(crosshost)-install_name_tool
configure_args=--host=$(crosshost)
else
CC=gcc $(extra_ldflags)
F77=gfortran -std=legacy -ffixed-line-length-none -fno-automatic $(extra_ldflags)
INSTALL_NAME_TOOL=install_name_tool
endif

# N.B.: need to include -static-libgcc as part of $CC, since libtool
# ignores $CFLAGS/$LDFLAGS when building a Windows DLL.  Furthermore,
# this must be set at *configure* time since the value of $CC gets
# baked into libtool.
ifneq ($(host),custom)
extra_ldflags=-static-libgcc -static-libgfortran
endif

SRC_DIR=$(shell pwd)
INSTALL_DIR:=$(shell pwd)/$(host)
BUILD_DIR=$(shell pwd)/$(host)/build

prefix = $(INSTALL_DIR)
bindir = $(INSTALL_DIR)/bin
libdir = $(INSTALL_DIR)/lib
includedir = $(INSTALL_DIR)/include
buildbindir = $(BUILD_DIR)/bin

MATLAB=matlab

export nocheck
export nojavacheck
export PATH

# ensure that libraries installed in $(libdir) are visible to binaries
# (e.g. for tests)
export LD_LIBRARY_PATH:=$(libdir):$(LD_LIBRARY_PATH)
export DYLD_LIBRARY_PATH:=$(libdir):$(DYLD_LIBRARY_PATH)
export WINEPATH:=$(bindir);$(WINEPATH)

# add relocatable rpath to elf binaries: the following is equivalent
# to -Wl,-rpath,$ORIGIN/../lib, but by setting it here we prevent the
# '$' getting mangled by subsequent scripts and makefiles
export LD_RUN_PATH=$$ORIGIN/../lib

all: curl wfdb mse edr ecgpuwave dfa librdsampjni

.PHONY: all

################################################################
## Prebuilt binaries for Toolbox releases

## GNU/Linux (x86_64) binaries: built on Debian wheezy
##  * make, gcc, gfortran, gcj-jdk
install-linux:
	schroot -cwfdb-toolbox-build $(MAKE) install host=linux
	$(MAKE) installclean host=linux
clean-linux:
	$(MAKE) clean host=linux

## Windows (x86_64) binaries: built using
##  * gcc-mingw-w64, gfortran-mingw-w64 (Debian stretch)
##     (which requires quadmath even though we don't use it)
##  * zulu 1.8.0 for jni headers
##  * wine64, wine-binfmt (Debian stretch) for tests
install-windows:
	$(MAKE) install host=windows crosshost=x86_64-w64-mingw32 \
	  extra_curl_configure_args=--disable-pthreads \
	  F77="x86_64-w64-mingw32-gcc -std=legacy -ffixed-line-length-none -fno-automatic -static-libgcc" \
	  f77_extra_libs="-Wl,-Bstatic -lgfortran -lquadmath -Wl,-Bdynamic" \
	  JAVA_HOME=/home/benjamin/packages/zulu8.13.0.5-jdk8.0.72-win_x64 \
	  WINEPREFIX=$(SRC_DIR)/windows/build/.wine \
	  WINEARCH=win64 WINEDEBUG=warn+dll DISPLAY= nojavacheck=1
	rm -rf $(SRC_DIR)/windows/build/.wine
	$(MAKE) installclean host=windows
clean-windows:
	$(MAKE) clean host=windows

## Mac OS X (x86_64 + i686) binaries: built using
##  * crosstool-ng (diorcety)
##  * gfortran (5.3.0, --disable-libquadmath-support)
##  * Mac OS X 10.6 SDK
install-macosx: install-macosx-x86_64 install-macosx-i686
	mkdir -p macosx/bin
	mkdir -p macosx/lib
	( set -e; cd macosx/x86_64; \
	  for f in bin/* lib/*.dylib; do if [ -f $$f ]; then \
	    x86_64-apple-darwin9-lipo -create ../i686/$$f $$f -output ../$$f; \
	  fi; done )
	rm -rf macosx/x86_64/bin macosx/x86_64/lib
	rm -rf macosx/i686/bin macosx/i686/lib
install-macosx-x86_64:
	$(MAKE) install host=macosx/x86_64 MFLAGS= nocheck=1 \
	  crosshost=x86_64-apple-darwin9
	$(MAKE) installclean host=macosx/x86_64
install-macosx-i686:
	$(MAKE) install host=macosx/i686 MFLAGS= nocheck=1 \
	  crosshost=i686-apple-darwin9
	$(MAKE) installclean host=macosx/i686
clean-macosx:
	$(MAKE) clean host=macosx
	$(MAKE) clean host=macosx/x86_64
	$(MAKE) clean host=macosx/i686

.PHONY: install-linux clean-linux install-windows clean-windows
.PHONY: install-macosx install-macosx-x86_64 install-macosx-i686 clean-macosx

################################################################
## Clean

# Remove installed files that are only used while building
installclean: installclean-wfdb installclean-curl installclean-librdsampjni
	-rmdir $(libdir)
	rm -rf $(INSTALL_DIR)/include
	rm -rf $(INSTALL_DIR)/share
	rm -rf $(INSTALL_DIR)/man
	rm -rf $(INSTALL_DIR)/database

# Remove everything except installed binaries and downloaded sources
clean: installclean
	rm -rf $(BUILD_DIR)

# Remove everything including installed binaries and downloaded sources
distclean: clean
	rm -f curl-*.tar.gz
	rm -f wfdb-*.tar.gz
	rm -f ecgpuwave-*.tar.gz
	rm -f edr.c mse.c dfa.c
	rm -rf custom/*
	rm -rf linux/*
	rm -rf macosx/*
	rm -rf windows/*

.PHONY: installclean clean distclean

################################################################
## Download all dependencies without installing anything

download: $(CURL_ARCHIVE) $(WFDB_ARCHIVE) $(ECGPUWAVE_ARCHIVE) \
	  edr.c mse.c dfa.c

.PHONY: download

################################################################
## libcurl

clean-curl:
	rm -rf $(BUILD_DIR)/$(CURL_PKG)
	rm -f $(BUILD_DIR)/curl.isconfig
	rm -f $(BUILD_DIR)/curl.isbuilt
	rm -f curl.tar.gz
$(CURL_ARCHIVE):
	wget -O curl.tar.gz $(CURL_SOURCE)
	echo "$(CURL_SHA256)  curl.tar.gz" | sha256sum -c
	mv curl.tar.gz $(CURL_ARCHIVE)
$(BUILD_DIR)/curl.isconfig: $(CURL_ARCHIVE)
	mkdir -p $(BUILD_DIR)
	( cd $(BUILD_DIR) && tar xfz $(SRC_DIR)/$(CURL_ARCHIVE) )
	( cd $(BUILD_DIR)/$(CURL_PKG) && \
	  ./configure $(configure_args) \
	    CC="$(CC)" \
	    --prefix=$(prefix) \
	    --libdir=$(libdir) \
	    --bindir=$(buildbindir) \
	    --disable-static \
	    --without-ssl --without-zlib --without-libssh2 --disable-ldap \
	    --disable-rtsp --disable-dict --disable-telnet --disable-tftp \
	    --disable-pop3 --disable-imap --disable-smb --disable-smtp \
	    --disable-gopher --without-libidn $(extra_curl_configure_args) )
	touch $(BUILD_DIR)/curl.isconfig
$(BUILD_DIR)/curl.isbuilt: $(BUILD_DIR)/curl.isconfig
	( cd $(BUILD_DIR)/$(CURL_PKG) && $(MAKE) install )
	( set -e; cd $(libdir); \
	  if [ -f libcurl.dylib ]; then \
	    . ./libcurl.la; \
	    $(INSTALL_NAME_TOOL) -id @loader_path/../lib/$$dlname \
	      libcurl.dylib; \
	  fi )
	touch $(BUILD_DIR)/curl.isbuilt
curl: $(BUILD_DIR)/curl.isbuilt
installclean-curl:
	rm -f $(BUILD_DIR)/curl.isbuilt
	rm -rf $(libdir)/pkgconfig
	( set -e; if [ -f $(libdir)/libcurl.la ]; then \
	    cd $(libdir); . ./libcurl.la; \
	    if [ -f $$dlname ]; then \
	      cp $$dlname $$dlname-real; \
	      rm -f $$library_names; \
	      mv $$dlname-real $$dlname; \
	    fi; \
	  fi )
	rm -f $(libdir)/libcurl.la

.PHONY: curl clean-curl installclean-curl

################################################################
## WFDB (requires libcurl)

# FIXME: configure --without-xview; parallel make (10.5.25)

clean-wfdb:
	rm -rf $(BUILD_DIR)/$(WFDB_PKG)
	rm -f $(BUILD_DIR)/wfdb.isconfig
	rm -f $(BUILD_DIR)/wfdb.isbuilt
	rm -f wfdb.tar.gz
$(WFDB_ARCHIVE):
	wget -O wfdb.tar.gz $(WFDB_SOURCE)
	echo "$(WFDB_SHA256)  wfdb.tar.gz" | sha256sum -c
	mv wfdb.tar.gz $(WFDB_ARCHIVE)
$(BUILD_DIR)/wfdb.isconfig: PATH:=$(buildbindir):$(PATH)
$(BUILD_DIR)/wfdb.isconfig: $(WFDB_ARCHIVE) $(BUILD_DIR)/curl.isbuilt
	mkdir -p $(BUILD_DIR)
	( cd $(BUILD_DIR) && tar xfz $(SRC_DIR)/$(WFDB_ARCHIVE) )
	( cd $(BUILD_DIR)/$(WFDB_PKG) && \
	  ./configure $(configure_args) \
	    --prefix=$(prefix) \
	    --libdir=$(libdir) \
	    --with-libcurl )
	sed -e "s/ DBDIR//" -i $(BUILD_DIR)/$(WFDB_PKG)/lib/wfdblib.h0
	sed -e "s, /usr/database,," -i $(BUILD_DIR)/$(WFDB_PKG)/checkpkg/expected/lcheck.log-NETFILES
	touch $(BUILD_DIR)/wfdb.isconfig
$(BUILD_DIR)/wfdb.isbuilt: PATH:=$(buildbindir):$(PATH)
$(BUILD_DIR)/wfdb.isbuilt: $(BUILD_DIR)/wfdb.isconfig
	( cd $(BUILD_DIR)/$(WFDB_PKG) && \
	  make -j1 install CC="$(CC) -I$(includedir) -L$(libdir)" \
	    RPATHFLAGS= )
	[ -n "$(nocheck)" ] || ( cd $(BUILD_DIR)/$(WFDB_PKG) && make -j1 check )
	rm -f $(bindir)/psfd \
	      $(bindir)/hrmem \
	      $(bindir)/hrfft \
	      $(bindir)/pschart \
	      $(bindir)/hrlomb \
	      $(bindir)/hrplot \
	      $(bindir)/setwfdb \
	      $(bindir)/cshsetwfdb \
	      $(bindir)/ahaconvert \
	      $(bindir)/plot2d \
	      $(bindir)/plot3d \
	      $(bindir)/pnwlogin \
	      $(bindir)/url_view \
	      $(bindir)/wave \
	      $(bindir)/wave-remote \
	      $(bindir)/wavescript
	( set -e; if [ -f $(libdir)/libwfdb.dylib ]; then \
	    dlname=libwfdb.$(WFDB_MAJOR).dylib; \
	    $(INSTALL_NAME_TOOL) -id @loader_path/../lib/$$dlname \
	      $(libdir)/libwfdb.dylib; \
	    for f in $(bindir)/*; do \
	      $(INSTALL_NAME_TOOL) -change $(libdir)/$$dlname \
	        @loader_path/../lib/$$dlname $$f; \
	    done; \
	  fi )
	cp $(bindir)/wfdb-config $(buildbindir)
	cp $(bindir)/bxb $(buildbindir)
	touch $(BUILD_DIR)/wfdb.isbuilt
wfdb: $(BUILD_DIR)/wfdb.isbuilt
installclean-wfdb:
	rm -f $(BUILD_DIR)/wfdb.isbuilt
	rm -rf $(libdir)/ps
	( set -e; \
	  if [ -f $(libdir)/libwfdb.so ]; then \
	    cd $(libdir); \
	    dlname=libwfdb.so.$(WFDB_MAJOR); \
	    cp $$dlname $$dlname-real; \
	    rm -f libwfdb.so libwfdb.so.*.*; \
	    mv $$dlname-real $$dlname; \
	  elif [ -f $(libdir)/libwfdb.dylib ]; then \
	    cd $(libdir); \
	    dlname=libwfdb.$(WFDB_MAJOR).dylib; \
	    cp $$dlname $$dlname-real; \
	    rm -f libwfdb.dylib libwfdb.*.*.dylib; \
	    mv $$dlname-real $$dlname; \
	  else \
	    rm -f $(libdir)/libwfdb.dll.a $(libdir)/libwfdb.dll.a.*; \
	  fi )

.PHONY: wfdb clean-wfdb installclean-wfdb

################################################################
## librdsampjni (requires WFDB, JNI)

librdsampjni_srcdir = $(SRC_DIR)/../../dependencies/jni

clean-librdsampjni:
	rm -rf $(BUILD_DIR)/librdsampjni
	rm -f $(BUILD_DIR)/librdsampjni.isconfig
	rm -f $(BUILD_DIR)/librdsampjni.isbuilt
$(BUILD_DIR)/librdsampjni.isconfig: $(BUILD_DIR)/wfdb.isbuilt
	mkdir -p $(BUILD_DIR)/librdsampjni
	[ -x $(librdsampjni_srcdir)/configure ] || \
	  ( cd $(librdsampjni_srcdir) && ./autogen.sh )
	( cd $(BUILD_DIR)/librdsampjni && \
	  $(librdsampjni_srcdir)/configure $(configure_args) \
	    --prefix=$(prefix) \
	    CC="$(CC)" \
	    WFDB_CFLAGS=-I$(includedir) \
	    WFDB_LIBS="-L$(libdir) -lwfdb" )
	touch $(BUILD_DIR)/librdsampjni.isconfig
$(BUILD_DIR)/librdsampjni.isbuilt: $(BUILD_DIR)/librdsampjni.isconfig
	( cd $(BUILD_DIR)/librdsampjni && $(MAKE) install )
	[ -n "$(nocheck)$(nojavacheck)" ] || ( cd $(BUILD_DIR)/librdsampjni && $(MAKE) check )
	set -e; if [ -f $(bindir)/librdsampjni.dll ]; then \
	  ( cd $(bindir); ls libcurl-*.dll > librdsampjni.dep ); \
	  ( cd $(bindir); ls wfdb-*.*.dll >> librdsampjni.dep ); \
	fi
librdsampjni: $(BUILD_DIR)/librdsampjni.isbuilt
installclean-librdsampjni:
	rm -f $(BUILD_DIR)/librdsampjni.isbuilt
	( set -e; if [ -f $(libdir)/librdsampjni.la ]; then \
	    cd $(libdir); . ./librdsampjni.la; \
	    if [ -f $$dlname ]; then \
	      cp $$dlname $$dlname-real; \
	      rm -f $$library_names; \
	      mv $$dlname-real $$dlname; \
	    fi; \
	  fi )
	rm -f $(libdir)/librdsampjni.la

.PHONY: librdsampjni clean-librdsampjni installclean-librdsampjni

################################################################
## edr (ECG-derived respiration) (requires WFDB)

clean-edr:
	rm -f $(bindir)/edr
edr: $(bindir)/edr
$(bindir)/edr: edr.c $(BUILD_DIR)/wfdb.isbuilt
	mkdir -p $(bindir)
	$(CC) -I$(includedir) -L$(libdir) \
	  -o $(bindir)/edr -O edr.c -lm -lwfdb
edr.c:
	wget -O edr.c.tmp $(EDR_SOURCE)
	echo "$(EDR_SHA256)  edr.c.tmp" | sha256sum -c
	mv edr.c.tmp edr.c

.PHONY: edr clean-edr

################################################################
## mse (Multi-scale entropy)

clean-mse:
	rm -f $(bindir)/mse
mse: $(bindir)/mse
$(bindir)/mse: mse.c
	mkdir -p $(bindir)
	$(CC) -o $(bindir)/mse -O mse.c -lm
mse.c:
	wget -O mse.c.tmp $(MSE_SOURCE)
	echo "$(MSE_SHA256)  mse.c.tmp" | sha256sum -c
	mv mse.c.tmp mse.c

.PHONY: mse clean-mse

################################################################
## ecgpuwave (requires WFDB)

clean-ecgpuwave:
	rm -rf $(BUILD_DIR)/$(ECGPUWAVE_PKG)
	rm -f $(BUILD_DIR)/ecgpuwave.isbuilt
$(ECGPUWAVE_ARCHIVE):
	wget -O ecgpuwave.tar.gz $(ECGPUWAVE_SOURCE)
	echo "$(ECGPUWAVE_SHA256)  ecgpuwave.tar.gz" | sha256sum -c
	mv ecgpuwave.tar.gz $(ECGPUWAVE_ARCHIVE)
$(BUILD_DIR)/ecgpuwave.isbuilt: PATH:=$(buildbindir):$(PATH)
$(BUILD_DIR)/ecgpuwave.isbuilt: $(BUILD_DIR)/wfdb.isbuilt
$(BUILD_DIR)/ecgpuwave.isbuilt: $(ECGPUWAVE_ARCHIVE)
	mkdir -p $(BUILD_DIR)
	( cd $(BUILD_DIR) && tar xfz $(SRC_DIR)/$(ECGPUWAVE_ARCHIVE) )
	( cd $(BUILD_DIR)/$(ECGPUWAVE_PKG) && \
	  $(MAKE) CC="$(CC)" F77="$(F77)" \
	    WFDB_CFLAGS="-I$(includedir)" \
	    WFDB_LIBS="-L$(libdir) -lwfdb $(f77_extra_libs)" \
	    INCDIR=$(includedir) )
	cp $(BUILD_DIR)/$(WFDB_PKG)/data/100s.* $(BUILD_DIR)/$(ECGPUWAVE_PKG)/
	[ -n "$(nocheck)" ] || \
	  ( cd $(BUILD_DIR)/$(ECGPUWAVE_PKG) && $(MAKE) check -o ecgpuwave )
	mkdir -p $(bindir)
	cp -v $(BUILD_DIR)/$(ECGPUWAVE_PKG)/ecgpuwave $(bindir)
	touch $(BUILD_DIR)/ecgpuwave.isbuilt
ecgpuwave: $(BUILD_DIR)/ecgpuwave.isbuilt

.PHONY: ecgpuwave clean-ecgpuwave

################################################################
## dfa (Detrended fluctuation analysis)

clean-dfa:
	rm -f $(bindir)/dfa
dfa.c:
	wget -O dfa.c.tmp $(DFA_SOURCE)
	echo "$(DFA_SHA256)  dfa.c.tmp" | sha256sum -c
	mv dfa.c.tmp dfa.c
dfa: $(bindir)/dfa
$(bindir)/dfa: dfa.c
	mkdir -p $(bindir)
	$(CC) -o $(bindir)/dfa -O dfa.c -lm

.PHONY: dfa clean-dfa

################################################################
## Install files from build into bin and/or lib

install: all
	( set -e; cd $(bindir); \
	  if [ -f wfdb-*.dll ]; then \
	    for f in *; do \
	      case $$f in *.*);; *) mv $$f $$f.exe;; esac; \
	    done; \
	  fi )

#Test will run the MATLAB Unit tests headlessly
#This requires the complete code repository and that the Makefile
#is run under [root-install-dir]/wfdb-app-tolbox/mcode/nativelibs/linux-amd64/ directory
test:
	cd ../ ;\
	$(MATLAB) -nodesktop -nosplash -nodisplay -r "addpath(pwd);cd ../UnitTests;BatchTest;exit"

#Package will clean all temporary files
#generated by this Makefile so that the Toolbox binaries
#are ready to be deployed
package:
	rm -rf ./tmp/
	rm -rf $(BUILD_DIR)
	rm curl* ecgpuwave* edr* mse* wfdb* *~

.PHONY: install test package
