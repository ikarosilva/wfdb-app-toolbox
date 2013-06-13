%  WaveForm DataBase (WFDB) Toolbox 
%  Version Beta NA 
% 
%This is a set of MATLAB functions and wrappers for reading, writing, and processing
%files in the formats used by PhysioBank databases (among others). 
%The WFDB Toolbox has support for reading public PhysioNet databases directly from 
%web. This feature allows your code to analyze a wide range of physiological 
%signals available from PhysioBank without the need to download entire 
%records and to store them locally. For more information please go to
% http://www.physionet.org 
%
%
%This source code for the library is distributed under the GPL license.
%
% 
%
%  Table of Contents (T0C)
% -----------------------
%   ann2rr          - Extract a list of intervals from an annotation file	
%   mat2wfdb        - Writes a MATLAB variable into a WDFB record file
%   physionetdb     - Get information about all of PhysioNet's available databases and signals
%   rdann           - Read annotation files for WFDB records
%   rdsamp          - Read signal files of WFDB records
%   score2013       - Scores entries to the PhysioNet 2013 Fetal ECG challenge
%   sqrs            - Finds the QRS complexes of a WFDB ECG record signal
%   tach            - Calculates instantaneous heart rate of a WFDB ECG record signal
%   wfdb            - Prints this help information of the Toolbox
%   wfdbdemo        - Demonstration of the WFDB App Toolbox
%   wfdbdesc        - Return signal information for about a WFDB record
%   wfdblicense     - License information about this Toolbox
%   wfdbtime        - Converts sample index to WFDB Time based on WFDB record information
%   wfdbtest        - Script to test installation of the Toolbox.
%   wqrs            - Finds the QRS complexes of a WFDB ECG record signal
%   wrann           - Writes annotations for WFDB records into annotation files
%   wrsamp          - Writes signal data into WFDB-compatible records
%
%
%
%   Contact: wfdb-matlab-support@physionet.org
%
%   Contributors:
%
%   Ikaro Silva (ikaro@mit.edu)
%   Daniel J. Scott
%   Michael Craig
%   George Moody


%Created by Ikaro Silva 2012