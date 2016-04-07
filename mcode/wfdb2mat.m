function wfdb2mat(varargin)
%
% wfdm2mat(recordName,signaList,N,N0)
%
%    Wrapper to WFDB WFDB2MAT:
%         http://physionet.org/physiotools/wag/wfdb2m-1.htm
%
% Converts a WFDB-compatible signal file to MATLAB/Octave *.mat file.
% The output files are recordNamem.mat and recordNamem.hea. The standard output of 
% WFDB2MAT will be saved in a file recordNamem.info. 
%
% Required Parameters:
%
% recorName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% Optional Parameters are:
%
% signalList
%       A Mx1 array of integers. Read only the signals (columns)
%       named in the signalList (default: read all signals).
% N
%       A 1x1 integer specifying the sample number at which to stop reading the
%       record file (default read all the samples = N).
% N0
%       A 1x1 integer specifying the sample number at which to start reading the
%       record file (default 1 = first sample).
%
%
% 
% NOTE: 
%       You can use the WFDB2MAT command in order to convert the record data into a *.mat file, 
%       which can then be loaded into MATLAB/Octave's workspace using the LOAD command.        
%       This will load the signal data in raw units (use RDMAT to load the signal in physical units). 
%
%
% Written by Ikaro Silva, 2014
% Last Modified: September 15, 2014
% Version 0.1
%
% Since 0.9.7
%
% %Example:
% wfdb2mat('mitdb/200')
% [tm,signal,Fs,labels]=rdmat('200m');
% 
%
% See also RDSAMP, RDMAT

%endOfHelp

persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('wfdb2mat');
end

%Set default pararameter values
inputs={'recordName','signalList','N','N0'};
signalList=[];
N=[];
N0=1;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-f',['s' num2str(N0-1)]};

if(~isempty(N))
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=['s' num2str(N)];
end

if(~isempty(signalList))
    wfdb_argument{end+1}='-s ';
    %-1 is necessary because WFDB is 0 based indexed.
    for sInd=1:length(signalList)
        wfdb_argument{end+1}=[num2str(signalList(sInd)-1)];
    end
end

data=javaWfdbExec.execToStringList(wfdb_argument);


