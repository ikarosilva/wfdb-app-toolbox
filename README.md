<p align="center" >
  <img src="http://physionet.org/physiotools/matlab/wfdb-app-matlab/wfdbrecordviewerTB.png" alt="wfdbRecordViewer" title="wfdbRecordViewer" />
</p>

## Introduction
The WFDB Toolbox for MATLAB and Octave is a set of Java, GUI, and m-code wrapper functions,
which make system calls to [WFDB Software Package](http://physionet.org/physiotools/wfdb.shtml) and other PhysioToolkit applications. The website for the toolbox (which includes the installation instructions) can be found at:

http://physionet.org/physiotools/matlab/wfdb-app-matlab/

Using the WFDB Toolbox, MATLAB and Octave users have access to over 50 [PhysioNet](http://physionet.org/) databases (over 4 TB of physiologic signals including ECG, EEG, EMG, fetal ECG, PLETH, PPG, ABP, respiration, and more).
Additionally, most of these databases are also accompanied by metadata such as expert annotations of
physiologically relevant events in WFDB annotation files. These can include, for example, 
cardiologists' beat and rhythm annotations of ECGs, or sleep experts' hypnograms (sleep stage annotations) 
of polysomnograms. All of these physiologic signals and annotations can be read on demand from the
PhysioNet web server and its mirrors using the toolbox functions, or from local copies if you choose 
to download them. This feature allows your code to analyze the wide range of physiologic signals 
available from PhysioBank without the need to download entire records and to store them locally.
The Toolbox is open-source (distributed under the GPL). The toolbox includes a GUI (WFDBRECORDVIEWER)
for facilitating the browsing, exploration, and analysis of WFBD records stored locally on the users machine, 
or remotely in PhysioNet's [databases](http://physionet.org/physiobank/database/DBS).

## Forum

A community discussion group is available at:
http://groups.google.com/forum/#!forum/wfdb-app-toolbox

## Available Databases

For a list of available databases accessible through the WFDB Toolbox, see:

http://physionet.org/physiobank/database/DBS

## Installing from PhysioNet

To check out and install from PhysioNet using MATLAB, run the following commands:

```
[old_path]=which('rdsamp');if(~isempty(old_path)) rmpath(old_path(1:end-8)); end
wfdb_url='https://physionet.org/physiotools/matlab/wfdb-app-matlab/wfdb-app-toolbox-0-10-0.zip';
[filestr,status] = urlwrite(wfdb_url,'wfdb-app-toolbox-0-10-0.zip');
unzip('wfdb-app-toolbox-0-10-0.zip');
cd mcode
addpath(pwd);savepath

```
## Checking out and installing from the trunk

Building the toolbox requires:
- The GNU C compiler (GCC)
- The GNU Fortran compiler (gfortran)
- GNU Make
- GNU Autoconf
- GNU Libtool
- Java Development Kit
- Ant

To build the toolbox, simply run 'make' in the top-level directory.
This will automatically download various dependencies from PhysioNet
and elsewhere (see 'mcode/nativelibs/Makefile' for details.)

## Reference & Toolbox Technical Overview

[An Open-source Toolbox for Analysing and Processing PhysioNet Databases in MATLAB and Octave.
I Silva, GB Moody, Journal of Open Research Software 2 (1), e27](http://openresearchsoftware.metajnl.com/article/view/jors.bi/77)


[WFDB Software Package](http://physionet.org/physiotools/wfdb.shtml) 

