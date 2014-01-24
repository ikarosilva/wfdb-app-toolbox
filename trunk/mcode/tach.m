function varargout=tach(varargin)
%
% [hr]=tach(recordName,annotator,N,N0,ouputSize)
%
%    Wrapper to WFDB TACH:
%         http://www.physionet.org/physiotools/wag/tach-1.htm
%
%    Reads a WFDB record and Annotation file to return:
%
%
% hr     
%       Nx1 vector of doubles representing a uniformly sampled and
%       smoothed instantaneous heart rate signal. The output are samples 
%       of the instantaneous heart rate signal in units of beats per minute.
%
% Required Parameters:
%
% recorName
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
%       annotation file (default read all = N).
% N0 
%       A 1x1 integer specifying the sample number at which to start reading the 
%       annotation file (default 1 = begining of the record).
%
% outputSize
%
%    A 1x1 integer specifying the number of output samples (ie estimated
%    heart rate intervals) such that the output 'hr' is a vector of 
%    size (outputSize-1) x 1.
%
%
% Written by Ikaro Silva, 2013
% Last Modified: January 24, 2014
% Version 1.1
%
% Since 0.0.1
%
% %Example 1- Read a signal and annotaion from PhysioNet's Remote server:
%[hr]=tach('challenge/2013/set-a/a01','fqrs'); 
%plot(hr);grid on;hold on

%endOfHelp
persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('tach');
end

%Set default pararamter values
inputs={'recordName','annotator','N','N0','ouputSize'};
outputs={'data(:,1)'};
N=[];
N0=1;
ouputSize=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

N0=num2str(N0-1); %-1 is necessary because WFDB is 0 based indexed.
wfdb_argument={'-r',recordName,'-a',annotator,'-f',['s' N0]};

if(~isempty(N))
    wfdb_argument{end+1}='-t';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=['s' num2str(N-1)];
end
    
if(~isempty(ouputSize))
    wfdb_argument{end+1}='-n';
    wfdb_argument{end+1}=[num2str(ouputSize)];
end

data=javaWfdbExec.execToDoubleArray(wfdb_argument);
if(config.inOctave)
    data=java2mat(data);
end
for n=1:nargout
        eval(['varargout{n}=' outputs{n} ';'])
end


