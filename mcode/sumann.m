function varargout=sumann(varargin)
%
% report=sumann(recName,annName,stopTime,qrsAnnotationsOnly)
%
%    Wrapper to WFDB SUMANN:
%         http://www.physionet.org/physiotools/wag/sumann-1.htm
%
% Reads a WFDB annotation file and summarize its contents.
% 
% Ouput Parameters:
%
% report 
%       String with the contaning summary of the contents, including the 
%       number of annotations of each type as well the duration and number of 
%      episodes of each rhythm and signal quality.
%
%Input Parameters:
% recName    
%       String specifying the WFDB record file.
%
% annName    
%       String specifying the reference WFDB annotation file.
%
% stopTime (Optional)
%       String specifying the stop time in WFDB format (default is end of
%       record).
%
% qrsAnnotationsOnly (Optional)
%       1x1 Boolean. If true, summarize QRS annotation only (default = 0).
%
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
% Since 0.9.0
%
% %Example (this will generate a /mitdb/100.qrs file at your directory):
%
% report=sumann('mitdb/100','atr');
%
%
%
% See also RDANN, MXM, WFDBTIME, BXB

%endOfHelp
persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('sumann');
end

%Set default pararamter values
inputs={'recName','annName','stopTime','qrsAnnotationsOnly'};
recName=[];
annName=[];
stopTime=[];
qrsAnnotationsOnly=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recName,'-a',annName};

if(~isempty(stopTime))
     wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=stopTime;
end
if(qrsAnnotationsOnly)
     wfdb_argument{end+1}='-q';
end

report=javaWfdbExec.execToStringList(wfdb_argument);
if(nargout>0)
   varargout{1}=report; 
end
