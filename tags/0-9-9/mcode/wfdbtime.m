function varargout=wfdbtime(varargin)
%
% [timeStamp,dateStamp]=wfdbtime(recordName,samples)
%
%    Wrapper to WFDB WFDBTIME:
%         http://www.physionet.org/physiotools/wag/wfdbti-1.htm
%
% Converts sample indices from recordName into timeStamp and dateStamps.
% Returns:
%
% timesStamp
%       Nx1 vector of cell Strings representing times stamps with respect to the
%       first sample in recordName.
%
% dateStamp
%       Nx1 vector of cell Strings representing date stamps with respect to the
%       first sample in recordName.
%
%
% Required Parameters:
%
% recorName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% samples
%       Nx1 vector of integers (indices) of samples from the signal in recordName (indices are
%       relative to the first sample).
%
%
%%Example
%[timeStamp,dateStamp]=wfdbtime('challenge/2013/set-a/a01',[1 10 30]')
%
%
%
% Written by Ikaro Silva, 2013
% Last Modified: March 24, 2014
% Version 1.1
% Since 0.0.1
%
% See also RDANN, WFDBDESC
%

%endOfHelp
persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('wfdbtime');
end

%Set default pararamter values
inputs={'recordName','samples'};
outputs={'timeStamp','dateStamp'};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Convert all the annoation to strings and send them as arguments
%TODO: maybe send ast STDIN ?
N=length(samples);
timeStamp=cell(N,1);
dateStamp=cell(N,1);
wfdb_argument=cell(N+2,1);
wfdb_argument{1}='-r';
wfdb_argument{2}=recordName;
samples=num2str(samples(:));
for n=1:N
    wfdb_argument{n+2}=['s' samples(n,:)];
end

data=javaWfdbExec.execToStringList(wfdb_argument).toArray;
if(config.inOctave)
    tmpData=data;
    data=cell(N,1);
    for i=1:N
        data(i)=char(tmpData(i));
    end
    clear tmpData;
end
for n=1:length(data)
    str=regexp(data(n,1),'\s+','split');
    if(config.inOctave)
        str=str{:};
    end
    timeStamp(n)=str(3);
    dateStamp(n)=str(4);
end

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end
