function varargout=wqrs(varargin)
%
% wqrs(recordName,N,N0,signal,threshold,findJ,powerLineFrequency,resample)
%
%    Wrapper to WFDB WQRS:
%         http://www.physionet.org/physiotools/wag/wqrs-1.htm
%
%    Creates a WQRS annotation file  at the current MATLAB directory.
%    The annotation file will have the same name as the recorName file,
%    but followed with the *.wqrs suffix. Use RDANN to read the annoations
%    into MATLAB's workspace in order to read the sample QRS locations.
%
%    If recordName is the path to a record at PhysioNet's database, then
%    the annation files will be stored in a subdirectory with the same relative 
%    path as recordName and under the current directory.
%
%
%    NOTE: In order to read the generated annotation file using RDANN, it is
%    necessary to have the WFDB record (*.hea and *.dat) files in the same 
%    directory as the annotation file.
%
%
% CITING CREDIT: To credit this function, please cite the following paper in your work:
%
% Zong, W., G. B. Moody, and D. Jiang."A robust open-source algorithm to detect onset 
% and duration of QRS complexes." Computers in Cardiology, 2003. IEEE, 2003.
%
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
%       A 1x1 integer. Specify the signal to obtain the annotation (default
%       = 1, first signal).
%
% threshold
%       A 1x1 double. Specify the detection threshold in millivolts
%      (default = 100). Use higher values to reduce false detections, or lower values to 
%       reduce the number of missed beats. 
%
% findJ
%       A 1x1 boolean. Find and annotate J-points (QRS ends) as well as QRS onsets. 
%       Default is false.
%
%
% powerLineFrequency
%       A 1x1 double. Specify the power line main frequency in Hz (default=
%       60 Hz), wqrs will apply a notch filter of the specified frequency 
%       to the input signal before length-transforming it. 
%
% resample
%       A 1x1 boolean. Resample the input at 120 Hz if the power line frequency 
%       is 60 Hz, or at 150 Hz otherwise (default= false : do not resample).
%
%
%
% Source code written by Wei Zong and George B. Moody. 
%
% MATLAB wrapper written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
% Since 0.0.1
%
% %Example - Requires write permission to current directory
%wqrs('challenge/2013/set-a/a01');

%endOfHelp
persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('wqrs');
end

%Set default pararamter values
inputs={'recordName','N','N0','signal','threshold', ...
    'findJ','powerLineFrequency','resample'};
N=[];
N0=1;
signal=[]; %use application default
threshold=[];%use application default
findJ=[];
powerLineFrequency=[];
resample=[];
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
if(~isempty(findJ) && findJ)
    wfdb_argument{end+1}='-j';
end

if(~isempty(powerLineFrequency))
    wfdb_argument{end+1}='-p';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=num2str(powerLineFrequency);
end

if(~isempty(resample) && resample)
    wfdb_argument{end+1}='-R';
end

javaWfdbExec.execToStringList(wfdb_argument);
    


