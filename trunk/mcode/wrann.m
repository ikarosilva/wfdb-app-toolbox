function varargout=wrann(varargin)
%
% wrann(recordName,annotator,ann,Anntype,subtype,chan,num)
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
% Anntype
%       Nx1 vector of the chars describing annotaion type.
%
% subtype
%       Nx1 vector of the chars describing annotaion subtype.
%
% chan
%       Nx1 vector of the ints describing annotaion subtype.
%
% num
%       Nx1 vector of the ints describing annotaion NUM.
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
% Last Modified: -
% Version 1.0
%
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
inputs={'recordName','annotator','ann','Anntype','subtype','chan','num'};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-a',annotator};

%Convert all the annoation to strings, in order to set as standard input
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
for i=1:L
    data(end+1,:)=sprintf('%s  %7ld %6s%5d%5d%5d',annTimeStamp(i,:),ann(i),Anntype(i),subtype(i),...
        chan(i),num(i));
end

javaWfdbExec.setArguments(wfdb_argument);
javaWfdbExec.execWithStandardInput(cellstr(char(data)));

