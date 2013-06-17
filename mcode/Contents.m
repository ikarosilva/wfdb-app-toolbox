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
%   bxb             - ANSI/AAMI-standard beat-by-beat annotation comparator.	
%   mat2wfdb        - Writes a MATLAB variable into a WDFB record file
%   mxm             TODO: - ANSI/AAMI-standard measurement-by-measurement annotation comparator.
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
%   wfdbupdate      - Checks if this versio of the WFDB Toolbox is up-to-date
%
%
% 
%   To credit this toolbox, please cite the following paper at your work:
%    
%   Goldberger AL, Amaral LAN, Glass L, Hausdorff JM, Ivanov PCh, Mark RG, Mietus JE, Moody GB, Peng CK, Stanley HE. 
%   "PhysioBank, PhysioToolkit, and PhysioNet: Components of a New Research Resource for Complex 
%   Physiologic Signals."
%   Circulation 101(23):e215-e220 
%   [http://circ.ahajournals.org/cgi/content/full/101/23/e215]; 
%   2000 (June 13). 
%   PMID: 10851218; doi: 10.1161/01.CIR.101.23.e215 
%
%
%   In addition, some of these functions use binary executables compiled
%   from open-source third-party code contributed to PhysioNet. When using
%   these functions on your work, please look at the help for that function
%   in order find out how to credit the original paper and authors.
%
%   For questions and feedback please contact us at: wfdb-matlab-support@physionet.org
%
%   Contributors:
%
%   Ikaro Silva 
%   George Moody 
%   Daniel J. Scott
%   Michael Craig
%   


%Created by Ikaro Silva 2012