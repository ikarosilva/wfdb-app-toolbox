#!/bin/bash
# build_wfdbjava.sh
# download and build all of the native libraries to support wfdbjava;
# only tested on gnu/linux
# FIXME: include -fno-stack-protector


#
#
#
#if [ ! -n "$1" ] || [ ! -n "$2" ]
#then
#    echo "Usage: $0 <install_dir> <java_home> <software>"
#fi

#Script not functional yet!
arg1="/home/ikaro/workspace/wfdb-app-toolbox/mcode/nativelibs/linux-amd64"

#Where <software> is one of the following options:
#
# 
#
#

cd $arg1
mkdir tmp
cd tmp


#
# build libgpg-error
#
#wget ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.7.tar.bz2
#tar xvfj libgpg-error-1.7.tar.bz2
#cd libgpg-error-1.7
#./configure --prefix=$arg1
#make
#make install
#cd ..


#
# build libidn
#
#wget ftp://aeneas.mit.edu/pub/gnu/libidn/libidn-1.12.tar.gz
#tar xvfz libidn-1.12.tar.gz
#cd libidn-1.12
#./configure --prefix=$arg1
#make
#make install
#cd ..


#
# build libgcrypt
#
#wget ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.4.4.tar.bz2
#tar xvfj libgcrypt-1.4.4.tar.bz2
#cd libgcrypt-1.4.4
#./configure --prefix=$arg1 --with-gpg-error-prefix=$1
#make
#make install
#cd ..


#
# build gnutls
#
wget http://ftp.gnu.org/pub/gnu/gnutls/gnutls-2.6.4.tar.bz2
tar xvfj gnutls-2.6.4.tar.bz2
cd gnutls-2.6.4
./configure --prefix=$1 --with-libgcrypt-prefix=$1 --without-zlib
make
make install
cd ..


#
# build curl
#
#wget http://curl.hoxt.com/download/curl-7.19.3.tar.bz2
#tar xvfj ...
wget http://www.physionet.org/physiotools/libcurl/curl-7.20.1.tar.gz 
tar xvf curl-7.20.1.tar.gz
cd curl-7.20.1
./configure --prefix=$arg1 --with-gnutls=$arg1 --with-libidn=$arg1 \
            --without-ssl --without-zlib --without-libssh2 --disable-ldap
make
make install
cd ..


#
# build wfdb
# FIXME: the version number changes!
#

wget http://www.physionet.org/physiotools/wfdb.tar.gz
tar xvfz wfdb.tar.gz
cd wfdb-10.5.18
PATH=$arg1/bin:$PATH ./configure --prefix=$arg1 --with-libcurl
PATH=$arg1/bin:$PATH make
PATH=$arg1/bin:$PATH make install
cd ..


#TODO: add packaging

