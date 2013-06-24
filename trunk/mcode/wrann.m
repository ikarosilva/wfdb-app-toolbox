function varargout=wrann(varargin)
%
% wrann(recordName,annotator,ann,AnnType,subType,chan,num)
%
%    Wrapper to WFDB WRANN:
%         http://www.physionet.org/physiotools/wag/wrann-1.htm
%
% Writes data into a WFDB annotation file. The file will be saved at the
% current directory (if the record is in the current directory) or, if a using
% a PhysioNet web record , a subdirectory in the current directory, with
% the relative path determined by recordName. The files will have the same
% name is the recordName but with a 'annotator' extension. You can use RDANN to
% verify that the write was completed sucessfully (see example below).
%
%
%
% NOTE: The WFDB Toolbox uses 0 based index, and MATLAB uses 1 based index.
%       Due to this difference annotation values ('ann') are shifted inside
%       this function in order to be compatible with the WFDB native
%       library. The MATLAB user should leave the indexing conversion to
%       the WFDB Toolbox.
%
% Required Parameters:
%
% recorName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% annotator
%       String specifying the name of the annotation file in the WFDB path or
%       in the current directory.
%
% ann
%       Nx1 vector of the integers. The time of the annotation, in samples,
%       with respect to the signals in recordName. The values of ann are
%       sample numbers (indices) with respect to the begining of the
%       record.
%
% AnnType
%       Nx1 vector of the chars or scalar describing annotaion type. Default is 'N'.
%
% subType
%       Nx1 vector of the chars or scalar describing annotaion subtype. Default is
%       '0'.
%
% chan
%       Nx1 vector of the ints or scalar describing annotaion subtype. Default is 0.
%
% num
%       Nx1 vector of the ints or scalar describing annotaion NUM. Default is 0.
%
%
%%Example- Creates a *.test file in your current directory
%[ann,type,subtype,chan,num]=rdann('challenge/2013/set-a/a01','fqrs');
% wrann('challenge/2013/set-a/a01','test',ann,type,subtype,chan,num)
%
%
% %Reading the file again should give the same results
%[ann,type,subtype,chan,num]=rdann('challenge/2013/set-a/a01','fqrs');
%wrann('challenge/2013/set-a/a01','test',ann,type,subtype,chan,num);
%[ann2,type2,subtype2,chan2,num2]=rdann('challenge/2013/set-a/a01','test',[],[],1);
%err=sum(ann ~= ann2)
%
% Written by Ikaro Silva, 2013
% Last Modified: 6/13/2013
% Version 1.0
% Since 0.0.1
%
% See also rdann, rdsamp, wfdbdesc
%

persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('wrann');
end

%Set default pararamter values
inputs={'recordName','annotator','ann','Anntype','subType','chan','num'};
AnnType='N';
subType='0';
chan=0;
num=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-a',annotator};

%Convert all the annoation to 0 based index and then to strings, in order to set as standard input
ann=ann-1;
del=repmat(' ',size(ann));

%WRANN expects the first column to be timestamps. So convert use the first
%column of data to generate the timestamps
%RDANN annotation fields are according to the following format:
%printf("%s  %7ld", mstimstr(annot.time), annot.time);
%printf("%6s%5d%5d%5d", annstr(annot.anntyp), annot.subtyp,annot.chan, annot.num);
%printf("\t%s", annot.aux + 1)

annTimeStamp=cell2mat(wfdbtime(recordName,ann));
L=length(annTimeStamp);
data=[];
if(length(AnnType)==1);
   annType=repmat(AnnType,[1 L]); 
end
if(length(subType)==1);
   subType=repmat(subType,[1 L]); 
end
if(length(chan)==1);
   chan=repmat(chan,[1 L]); 
end
if(length(num)==1);
   num=repmat(num,[1 L]); 
end
for i=1:L
    data(end+1,:)=sprintf('%s  %7ld %6s%5d%5d%5d',annTimeStamp(i,:),ann(i),annType(i),subType(i),...
        chan(i),num(i));
end

javaWfdbExec.setArguments(wfdb_argument);
javaWfdbExec.execWithStandardInput(cellstr(char(data)));

