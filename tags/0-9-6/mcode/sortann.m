function varargout=sortann(varargin)
%
% sortann(recName,annName,beginTime,stopTime,outFile)
%
%    Wrapper to WFDB SORTANN:
%         http://www.physionet.org/physiotools/wag/sortan-1.htm
%
% Rewrites the annotation file specified by recName and annName, arranging its contents in 
% canonical (time, num, and chan) order. The sorted (output) annotation file is always written 
% to the current directory. If the input annotation file is in the current directory, SORTANN
% replaces it unless you specify a different output annotator name (using the outFile option). 
% If the input annotations are already in the correct order, no output is written unless you 
% have used the outFile option.  
% 
%
%Input Parameters:
% recName    
%       String specifying the WFDB record file.
%
% annName    
%       String specifying the reference WFDB annotation file.
%
% stopTime (Optional)
%       String specifying the start time in WFDB format (default is beginning of
%       record).
%
% stopTime (Optional)
%       String specifying the stop time in WFDB format (default is end of
%       record).
%
% outFile (Optional)
%       String specifying the output annotation file name.
%
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
% Since 0.9.0
%
% %Example (this will generate a /mitdb/100.sortedATR file at your directory):
%
% sortann('mitdb/100','atr',[],[],'sortedATR');
% ann=rdann('mitdb/100','sortedATR');
%
%
% See also RDANN 

%endOfHelp
persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('sortann');
end

%Set default pararamter values
inputs={'recName','annName','beginTime','stopTime','outFile'};
recName=[];
annName=[];
beginTime=[];
stopTime=[];
outFile=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recName,'-a',annName};

if(~isempty(beginTime))
     wfdb_argument{end+1}='-f';
    wfdb_argument{end+1}=beginTime;
end
if(~isempty(stopTime))
     wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=stopTime;
end
if(~isempty(outFile))
    wfdb_argument{end+1}='-o';
     wfdb_argument{end+1}=outFile;
end

javaWfdbExec.execToStringList(wfdb_argument);
