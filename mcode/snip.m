function varargout=snip(varargin)
%
% err=snip(inputRecord,outputRecord,beginTime,stopTime,inputAnn,outFormat)
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
% Since 0.9.10
%
%
% %Example- Generate a record from the first minute of mitdb/100
%  Fs=360;
%  err=snip('mitdb/100','100cut',[],Fs*60);
%  [sig2,Fs,tm1]=rdsamp('mitdb/100');
%  [sig2,Fs,tm2]=rdsamp('100cut');
%  plot(tm1,sig1(:,1));hold on;grid on
%  plot(tm2,sig2(:,1),'r')
%
%
% See also RDSAMP, RDANN, WFDBDESC


%endOfHelp
persistent javaWfdbExec

if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('snip');
end

%Set default pararamter values

inputs={'inputRecord','outputRecord','beginTime','stopTime','inputAnn','outFormat'};
inputRecord=[];
outputRecord=[];
beginTime=[];
stopTime=[];
inputAnn=[];
outFormat=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-i',inputRecord,'-n',outputRecord,'-m'};

if(~isempty(beginTime))
    wfdb_argument{end+1}='-f';
    wfdb_argument{end+1}=['s ' num2str(beginTime-1)];
end
if(~isempty(stopTime))
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=['s ' num2str(stopTime)];
end
if(~isempty(inputAnn))
    wfdb_argument{end+1}='-a';
    wfdb_argument{end+1}=inputAnn;
end
if(~isempty(outFormat))
    wfdb_argument{end+1}='-O';
    wfdb_argument{end+1}=outFormat;
end

err=javaWfdbExec.execToStringList(wfdb_argument);
if(nargout>0)
    err=char(err.toString);
    if(strcmp(err,'[]'))
        err=[];
    end
    varargout{1}=err;
end
