function varargout=sqrs(varargin)
%
% sqrs(recordName,N,N0,signal,threshold)
%
%    Wrapper to WFDB SQRS:
%         http://www.physionet.org/physiotools/wag/sqrs-1.htm
%
%    Creates a SQRS annotation file  at the current MATLAB directory.
%    The annotation file will have the same name as the recorName file,
%    but followed with the *.qrs suffix. Use RDANN to read the annoations
%    into MATLAB's workspace in order to read the sample QRS locations.
%
%    If recordName is the path to a record at PhysioNet's database, than
%    the annation files will be stored in a subdirectory with the same relative 
%    path as recordName and under the current directory.
%
%    NOTE: In order to read the generated annotation file using RDANN, it is
%    necessary to have the WFDB record (*.hea and *.dat) files in the same 
%    directory as the annotation file.
%
% Required Parameters:
%
% recorName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
%
% Optional Parameters are:
%
% N 
%       A 1x1 integer specifying the sample number at which to stop reading the 
%       record file (default read all = N).
% N0 
%       A 1x1 integer specifying the sample number at which to start reading the 
%       annotion file (default 1 = begining of the record).
%
% signal
%       A 1x1 integer. Specify the singal to obtain the annotation (default
%       = 1, first signal).
%
% threshold
%       A 1x1 integer. Specify the detection threshold (default = 500).  
%       Use higher values to reduce false detections, or lower values to 
%       reduce the number of missed beats. 
%
%
% Source code by George B. Moody. The source code is a fairly literal translation with minor 
% corrections of the Pascal original by WAH Engelse and Cees Zeelenberg. 
%
% MATLAB wrapper written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
%
% Since 0.0.1 
%
% %Example
%sqrs('challenge/2013/set-a/a01',[],1000);

%endOfHelp

persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('sqrs');
end

%Set default pararamter values
inputs={'recordName','annotator','N','N0','signal','threshold'};
N=[];
N0=1;
signal=[]; %use application default
threshold=[];%use application default
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

N0=num2str(N0-1); %-1 is necessary because WFDB is 0 based indexed.
wfdb_argument={'-r',recordName,'-f',['s' N0]};

if(~isempty(N))
    wfdb_argument{end+1}='-t';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=['s' num2str(N-1)];
end
if(~isempty(signal))
    wfdb_argument{end+1}='-s';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=num2str(signal-1);
end
if(~isempty(threshold))
    wfdb_argument{end+1}='-m';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=num2str(threshold-1);
end

javaWfdbExec.execToStringList(wfdb_argument);
    


