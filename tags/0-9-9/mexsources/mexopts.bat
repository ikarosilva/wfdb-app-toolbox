@echo off
set MATLAB=%MATLAB%
set MW_TARGET_ARCH=win64
set MINGWROOT=C:\Program Files\mingw-w64\x86_64-4.9.2-posix-seh-rt_v3-rev0\mingw64\
set PATH=%MINGWROOT%\bin;%PATH%

set COMPILER=gcc
set COMPFLAGS=-c -m64 -mwin32 -mdll -Wall -DMATLAB_MEX_FILE
set OPTIMFLAGS=-DNDEBUG -O2
set DEBUGFLAGS=-g
set NAME_OBJECT=-o

set LINKER=gcc
set LIBLOC=%MATLAB%\extern\lib\%MW_TARGET_ARCH%\microsoft
set LINKFLAGS=-shared -L"%LIBLOC%" -L"%MATLAB%\bin\%MW_TARGET_ARCH%"
set LINKFLAGSPOST=-lmx -lmex -lmat -lwfdb
set LINKOPTIMFLAGS=-O2
set LINKDEBUGFLAGS=-g
set LINK_FILE=
set LINK_LIB=
set NAME_OUTPUT=-o "%OUTDIR%%MEX_NAME%%MEX_EXT%"

set RC_COMPILER=
set RC_LINKER=