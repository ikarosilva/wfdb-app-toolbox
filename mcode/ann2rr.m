function varargout=ann2rr(varargin)
%
% [RR,tms]=ann2rr(recordName,annotator,N,N0,consecutiveOnly)
%
%    Wrapper to WFDB ANN2RR:
%         http://www.physionet.org/physiotools/wag/ann2rr-1.htm
%
%    Reads a WFDB record and Annotation file to return:
%
%
% RR
%       Nx1 vector of integers representing the duration of the RR
%       interval in samples.
%
% tms
%       Nx1 vector of integers representing the beginning of the RR
%       interval in samples.
%
% Required Parameters:
%
% recordName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% annotator  -
%       String specifying the name of the annotation file in the WFDB path or
%       in the current directory.
%
% Optional Parameters are:
%
% N
%       A 1x1 integer specifying the sample number at which to stop reading the
%       record file (default read all = N).
% N0
%       A 1x1 integer specifying the sample number at which to start reading the
%       annotation file (default 1 = beginning of the record).
%
% consecutiveOnly
%       A 1x1 boolean. If true, prints intervals between consecutive valid
%       annotations only (default =true).
%
%
% Written by Ikaro Silva, 2013
% Last Modified: January, 16, 2013
% Version 1.1
%
% Since 0.0.1
% %Example
% [rr,tm]=ann2rr('challenge-2013/1.0.0/set-a/a01','fqrs');

%endOfHelp

persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('ann2rr');
end

%Set default parameter values
inputs={'recordName','annotator','N','N0','consecutiveOnly'};
outputs={'data(:,2)','data(:,1)'};
N=[];
N0=1;
consecutiveOnly=1;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Cache record and annotation
wfdbdownload(recordName);
try
    wfdbdownload([recordName '.' annotator]);
catch
    %This doesn't work for sqrs
end

N0=num2str(N0-1); %-1 is necessary because WFDB is 0 based indexed.
wfdb_argument={'-r',recordName,'-a',annotator,'-f',['s' N0]};

if(~isempty(N))
    wfdb_argument{end+1}='-t';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=['s' num2str(N-1)];
end

if(consecutiveOnly)
    wfdb_argument{end+1}='-c';
end
wfdb_argument{end+1}='-V';

data=javaWfdbExec.execToDoubleArray(wfdb_argument);
data=wfdbjava2mat(data);
for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';']);
end
