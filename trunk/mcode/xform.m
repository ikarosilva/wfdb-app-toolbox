function varargout=snip(varargin)
%
% err=snip(inputRecord,outputRecord,beginTime,stopTime,inputAnn,outSignalList,outFs)
%
%    Wrapper to WFDB SNIP:
%         http://www.physionet.org/physiotools/wag/snip-1.htm
%
% Copy an excerpt of a WFDB record  
%
%
%Input Parameters:
% inputRecord    
%       String specifying the input WFDB record file.
%
% outputRecord    
%       String specifying the output WFDB record file name that will be generated.
%
% beginTime (Optional)
%       Integer specifying start time of the output WFDB record. Default is
%       the beginning of the input record.
% 
% stopTime (Optional)
%       Integer specifying end time of the output WFDB record. Defaut is
%       end of input record.
%
% inputAnn (Optional)    
%       String specifying the annotation files to convert along with the
%       given record. Defaults i none (empty).
%
% outSignalList (Optional)
%       Array of integers specifying which signals to convert. Default is
%       to use all signals.
% 
% outFormat (Optional)
%       String specifying the output format (see http://www.physionet.org/physiotools/wag/header-5.htm).
%       Default is the same as input record.
%
%Output Parameters:
% err (Optional)
%       String spefiying any error messages. If empty, conversion was
%       sucessfull.
%
% Written by Ikaro Silva, 2015
% Last Modified: -
% Version 1.0
% Since 1.0
%
% See also RDSAMP, RDANN, WFDBDESC


%endOfHelp

persistent javaWfdbExec

persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('xform');
end

%Set default pararamter values

inputs={'inputRecord','outputRecord','beginTime','stopTime','inputAnn','outSignalList','outFs'};
inputRecord=[];
outputRecord=[];
beginTime=[];
stopTime=[];
inputAnn=[];
outSignalList=[];
outFs=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-i',inputRecord,'-o',outputRecord};

if(~isempty(beginTime))
     wfdb_argument{end+1}='-f';
    wfdb_argument{end+1}=['s ' num2str(beginTime-1)];
end
if(~isempty(stopTime))
     wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=['s ' num2str(stopTime-1)];
end
if(~isempty(inputAnn))
     wfdb_argument{end+1}='-a';
    wfdb_argument{end+1}=inputAnn;
end

if(~isempty(outSignalList))
     wfdb_argument{end+1}='-s';
    wfdb_argument{end+1}=[num2str(outSignalList-1)];
end

err=javaWfdbExec.execToStringList(wfdb_argument);

if(nargout>0) 
    vargout{1}=err;
end