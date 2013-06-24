function varargout=bxb(varargin)
%
% report=bxb(recName,refAnn,testAnn,reportFile,beginTime,stopTime,matchWindow)
%
%    Wrapper to WFDB BXB:
%         http://www.physionet.org/physiotools/wag/bxb-1.htm
%
% Creates a report file ("reportFile) using 
% ANSI/AAMI-standard beat-by-beat annotation comparator.
% 
% Ouput Parameters:
%
% report (Optional)
%       String with the contaning a log and beat label discrepancy
%       from the comparison execution.
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
% beginTime (Optional)
%       String specifying the begin time in WFDB time format. The
%       WFDB time format is described at
%       http://www.physionet.org/physiotools/wag/intro.htm#time.
%       Default starts comparison after 5 minutes.
%
% stopTime (Optional)
%       String specifying the stop time in WFDB format (default is end of
%       record).
%
% matchWindow (Optional)
%       1x1 WFDB Time specifying the match window size (default = 0.15 s).
%
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
% Since 0.9.0
%
% %Example (this will generate a /mitdb/100.qrs file at your directory):
% %Compares SQRS detetor with the MITDB ATR annotations
%
% [refAnn]=rdann('mitdb/100','atr');
% sqrs('mitdb/100');
% [testAnn]=rdann('mitdb/100','qrs');
% bxb('mitdb/100','atr','qrs','bxbReport.txt')
%
%
%
% See also RDANN, MXM, WFDBTIME


persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('bxb');
end

%Set default pararamter values
inputs={'recName','refAnn','testAnn','reportFile','beginTime','stopTime','matchWindow'};
recName=[];
refAnn=[];
testAnn=[];
reportFile=[];
beginTime=[];
stopTime=[];
matchWindow=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recName,'-a',refAnn,testAnn,'-S',reportFile,'-v'};

if(~isempty(beginTime))
     wfdb_argument{end+1}='-f';
    wfdb_argument{end+1}=beginTime;
end
if(~isempty(stopTime))
     wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=stopTime;
end
if(~isempty(matchWindow))
     wfdb_argument{end+1}='-w';
    wfdb_argument{end+1}=matchWindow;
end

report=javaWfdbExec.execToStringList(wfdb_argument);
if(nargout>0)
   varargout{1}=report; 
end
