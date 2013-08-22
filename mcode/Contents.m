%  WaveForm DataBase (WFDB) Toolbox 
%  Version Beta 0.9.3 
% 
%  Last Updated August 22, 2013
%
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
% 
%
%  Table of Contents (T0C)
% -----------------------
%   ann2rr          - Extract a list of intervals from an annotation file
%   bxb             - ANSI/AAMI-standard beat-by-beat annotation comparator.
%   lomb			- Estimate power spectrum using the Lomb periodogram method	
%   mat2wfdb        - Writes a MATLAB variable into a WDFB record file
%   maprecord       - Perform multithread batch processing of WFDB records 
%   mrgann          - Merge annotation files
%   mxm             TODO: - ANSI/AAMI-standard measurement-by-measurement annotation comparator.
%   physionetdb     - Get information about all of PhysioNet's available databases and signals
%   rdann           - Read annotation files for WFDB records
%   rdmimic2wave    - Searches MIMIC II matched waveform records within a clinical time range
%   rdsamp          - Read signal files of WFDB records
%   score2013       - Scores entries to the PhysioNet 2013 Fetal ECG challenge
%   sortann         - Rearrange annotations in canonical order
%   sqrs            - Finds the QRS complexes of a WFDB ECG record signal
%	sumann			- Summarize the contents of a WFDB annotation file
%	tach            - Calculates instantaneous heart rate of a WFDB ECG record signal
%   wfdb            - Prints this help information of the Toolbox
%   wabp			- Arterial blood pressure (ABP) pulse detector
%   wfdbdemo        - Demonstration of the WFDB App Toolbox
%   wfdbdesc        - Return signal information for about a WFDB record
%   wfdbtime        - Converts sample index to WFDB Time based on WFDB record information
%   wfdbtest        - Script to test installation of the Toolbox.
%   wqrs            - Finds the QRS complexes of a WFDB ECG record signal
%   wrann           - Writes annotations for WFDB records into annotation files
%   wrsamp          - Writes signal data into WFDB-compatible records
%   wfdbupdate      - Checks if this version of the WFDB Toolbox is up-to-date
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
%   This source code for the native libraries can be obtained from PhysioNet under
%   the GNU GPL aggreement.  
%
%   Contributors:
%
%   Ikaro Silva 
%   George Moody 
%   Daniel J. Scott
%   Michael Craig
%   


%Created by Ikaro Silva 2012