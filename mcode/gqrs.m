function varargout=gqrs(varargin)
%
% gqrs(recordName,N,N0,signal,threshold,outputName,highResolution)
%
%    Wrapper to WFDB GQRS:
%         http://www.physionet.org/physiotools/wag/gqrs-1.htm
%
%    Creates a SQRS annotation file  at the current MATLAB directory.
%    The detector algorithm is new and as yet unpublished.
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
%       A 1x1 double. Specify the detection threshold (default = 1.00).
%       If too many beats are missed, decrease threshold,
%       if there are too many extra detections, increase threshold.
%
% outputName
%       String. Save the ouput annotation file extension as *.outputName (default =
%       *.qrs).
%
% highResolution
%       Boolean. If false (0), does not read multifrequency signals in high
%       resolution mode.
%
%
% Source code by George B. Moody
%
% MATLAB wrapper written by Ikaro Silva, 2013
% Last Modified:  December 10, 2013
% Version 1.0
% See also SQRS, RDANN, WQRS, BXB
% Since 0.9.5
%
% %Example
% N=5000;
% gqrs('mitdb/100',N);
% ann=rdann('mitdb/100','qrs',[],N);
% [signal,Fs,tm]=rdsamp('mitdb/100',[],N);
% plot(tm,sig(:,1));hold on;grid on
% plot(tm(ann),sig(ann,1),'ro')

%endOfHelp

persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('gqrs');
end

%Set default pararamter values
inputs={'recordName','N','N0','signal','threshold','outputName','highResolution'};
N=[];
N0=1;
signal=[]; %use application default
threshold=[];%use application default
outputName=[];
highResolution=[];
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
if(~isempty(outputName))
    wfdb_argument{end+1}='-o';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=outputName;
end
if(~isempty(highResolution))
    if(logical(highResolution))
        wfdb_argument{end+1}='-H';
    end
end

err=javaWfdbExec.execToStringList(wfdb_argument);
if(~isempty(strfind(err.toString,['annopen: can''t'])))
    error(err)
end


