function varargout=mxm(varargin)
%
% mxm(recName,refAnn,testAnn,reportFile,beginTime,appendReport,mType,stopTime,normalize)
%
%    Wrapper to WFDB MXM:
%         http://www.physionet.org/physiotools/wag/mxm-1.htm
%
% ANSI/AAMI-standard measurement-by-measurement annotation comparator.
%
%
%Input Parameters:
% recName    
%       String specifying the WFDB record file.
%
% refAnn    
%       String specifying the reference WFDB annotation file.
%
% testAnn    
%       String specifying the test WFDB annotation file.
% 
% reportFile
%       String representing the file at which the report will be 
%       written to.
%
%
% beginTime (Optional)
%       String specifying the begin time in WFDB format. The
%       WFDB time format is described at
%       http://www.physionet.org/physiotools/wag/intro.htm#time.
%       Default starts comparison after 5 minutes.
%
% appendReport (Optional)
%       Boolean (default false). Append a line-format report to the
%       reportFile.
%
% mType (Optional)
%       String defining which measurement type to compare.
%
% stopTime (Optional)
%       String specifying the stop time in WFDB format (default is end of
%       record).
%
% normalize (Optional)
%      Boolean (default true). If false, calculates the unnormalized RMS
%      measurement error.
%
%
%TODO: INCLUDE Example
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
% Since 0.0.2 
%
% See also WRANN, RDANN


persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('mxm');
end

%Set default pararamter values
inputs={'recName','refAnn','testAnn','reportFile',...
    'beginTime','appendReport','mType','stopTime','normalize'};
recName=[];
refAnn=[];
testAnn=[];
reportFile=[];
beginTime=[];
appendReport=[];
mType=[];
stopTime=[];
normalize=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recName,'-a',[refAnn ' ' testAnn],'-l',reportFile};

if(~isempty(beginTime))
     wfdb_argument{end+1}='-f';
    wfdb_argument{end+1}=beginTime;
end
if(~isempty(mType))
     wfdb_argument{end+1}='-m';
    wfdb_argument{end+1}=mType;
end
if(~isempty(appendReport))
     wfdb_argument{end+1}='-s';
    wfdb_argument{end+1}=reportFile;
end
if(~isempty(stopTime))
     wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=stopTime;
end
if(~isempty(stopTime))
     wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=stopTime;
end
if(~isempty(normalize) && ~normalize)
     wfdb_argument{end+1}='-u';
end

data=javaWfdbExec.execToStringList(wfdb_argument);


