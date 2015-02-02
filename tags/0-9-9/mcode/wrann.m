function varargout=wrann(varargin)
%
% wrann(recordName,annotator,ann,annType,subType,chan,num,comments)
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
% annType
%       Nx1 vector of the chars or scalar describing annotation type. Default is 'N'.
%       For a list of standard annotation codes used by PhyioNet, please see:
%             http://www.physionet.org/physiobank/annotations.shtml
%
% subType
%       Nx1 vector of the chars or scalar describing annotation subtype.
%       Default is '0'.
%
% chan
%       Nx1 vector of the ints or scalar describing annotation CHAN. Default is 0.
%
% num
%       Nx1 vector of the ints or scalar describing annotation NUM. Default is 0.
%
% comments
%       Nx1 vector of the chars or scalar describing annotation comments. Default is ''.
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
%
%
% %Example 2
%[ann,type,subtype,chan,num]=rdann('mitdb/100','atr');
%wrann('mitdb/100','test',ann,type,subtype,chan,num);
%
% Written by Ikaro Silva, 2013
% Last Modified: November 4, 2014
% Version 1.4
% Since 0.0.1
%
% See also RDANN, RDSAMP, WFDBDESC
%

%endOfHelp
persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('wrann');
end

%Set default pararamter values
inputs={'recordName','annotator','ann','annType','subType','chan','num','comments'};
annType='N';
subType='0';
chan=0;
num=0;
comments=' ';
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-a',annotator};

%Exit if any annotatinos have a NaN
if(any(isnan(ann(:))))
   error('Annotation array contains NaNs...not able to write file!');
end

%Convert all the annoation to 0 based index and then to strings, in order to set as standard input
ann=ann-1;
del=repmat(' ',size(ann));

%WRANN expects the first column to be timestamps. So convert use the first
%column of data to generate the timestamps
%RDANN annotation fields are according to the following format:
%printf("%s  %7ld", mstimstr(annot.time), annot.time);
%printf("%6s%5d%5d%5d", annstr(annot.anntyp), annot.subtyp,annot.chan, annot.num);
%printf("\t%s", annot.aux + 1)

[annTimeStamp,annDateStamp]=wfdbtime(recordName,ann);
L=length(annTimeStamp);
data=cell(L,1);
if(length(annType)==1);
    annType=repmat(annType,[1 L]);
end
if(length(subType)==1);
    subType=repmat(subType,[1 L]);
end
if(length(chan)==1);
    chan=repmat(num2str(chan),[1 L]);
end
if(isnumeric(chan))
    chan=num2str(chan);
end
if(length(num)==1);
    num=repmat(num2str(num),[1 L]);
end
if(isnumeric(num))
    num=num2str(num);
end
if(length(comments)==1);
    comments=num2cell(repmat(num2str(comments),[1 L]));
end

ann=num2str(reshape(ann, [], 1));
if(iscell(comments{1}))
    %For compatiblitiy with output of RDANN
    for i=1:L
        comments{i}=cell2mat(comments{i});
    end
end

padDate=~strcmp(annDateStamp{1}(1),'[');
tab=char(9);
for i=1:L
    if(padDate)
        deli=strfind(annTimeStamp{i},':');
        if(deli==2)
            annDateStamp{i} = ['0' annDateStamp{i}];
        end
    end
    data{i}=[annDateStamp{i} ' ' ann(i,:) ' ' annType(i) ' ' ...
        subType(i) ' ' chan(i) ' ' num(i) tab comments{i}];
end

javaWfdbExec.setArguments(wfdb_argument);
err=javaWfdbExec.execWithStandardInput(data);
if(~isempty(strfind(err.toString,['annopen: can''t'])))
    error(char(err.toString))
end
