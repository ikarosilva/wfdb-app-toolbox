function varargout=mxm(varargin)
%
% [tm, signal]=mxm(recName,refAnn,testAnn,reportFile,beginTime)
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
% beginTime (Optional)
%       String specifying the begin time in WFDB format. The
%       WFDB time format is described at
%       http://www.physionet.org/physiotools/wag/intro.htm#time.
%       Default starts comparison after 5 minutes.
%
%
% reportFile
%       String representing the file at which the report will be 
%       written to.
%
% appendReport (Optional)
%       Boolean (default 
%
% Required Parameters:
%
% recorName 
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
%
%
% See also WRANN, RDANN


%@UNDER CONSTRUCTION

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
inputs={'recName','refAnn','testAnn','reportFile','beginTime'};
recName=[];
refAnn=[];
testAnn=[];
reportFile=[];
beginTime=[];

for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

if(isempty(beginTime))
    wfdb_argument={'-r',recName,'-a',[refAnn ' ' testAnn],'-l',reportFile};
else
    wfdb_argument={'-r',recName,'-a',[refAnn ' ' testAnn],...
        '-f',beginTime,'-l',reportFile};
end

data=javaWfdbExec.execToStringList(wfdb_argument);


