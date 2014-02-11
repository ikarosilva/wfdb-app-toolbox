function mrgann(varargin)
%
% mrgann(recName,annName1,annName2,outAnn,verbose)
%
%    Wrapper to WFDB MRGANN:
%         http://www.physionet.org/physiotools/wag/mrgann-1.htm
%
%
% Reads a pair of annotation files (annName1, annName2) for the specified 
% record (recName), and writes a third annotation file (specified by outAnn) 
% for the same record. Typical applications of MRGANN include combining annotation 
% files that apply to different signals within a multi-signal record, and replacing 
% a segment of an annotation file with annotations from another file. MRGANN cannot 
% concatenate annotation files from different records (e.g., segments of a multi-segment record).
%
%
%Required Parameters:
%
% recName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% annName1     
%       String specifying the name of the first WFDB annotation file to be
%       merged.
%
% annName2     
%       String specifying the name of the second WFDB annotation file to be
%       merged.
%
% outAnn
%       String specifying the name of the output WFDB annotation file
%       containing the merged annotations.
%
%
% Optional Parameters are:
%
% verbose
%       Boolean. If true warns about simultaneous annoations with matching
%       chan fields (default = true).
%
%
% MATLAB wrapper Written by Ikaro Silva, 2013
% Last Modified: 6/13/2013
% Version 1.0
%
% Since 0.9.0
% 
% See also BXB, RDANN, WRANN
%
%
% %Example 1- Read a signal and annotation from PhysioNet's Remote server:
% %and merge with calculated WRQS annotation
% wqrs('mitdb/100'); 
% mrgann('mitdb/100','atr','wqrs','testAnn')
%
%
% 
% See also wfdbtime, wrann

%endOfHelp

persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('mrgann');
end

%Set default pararamter values
% [ann,type,subtype,chan,num]=rdann(recordName,annotator,C,N,N0)
inputs={'recName','annName1','annName2','outAnn','verbose'};
verbose=1;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recName,'-i',annName1,annName2,'-o',outAnn};

if(verbose)
    wfdb_argument{end+1}='-v';
end
javaWfdbExec.execToStringList(wfdb_argument);
