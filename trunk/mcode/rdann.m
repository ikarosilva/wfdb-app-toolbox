function varargout=rdann(varargin)
%
% [ann,type,subtype,chan,num,comments]=rdann(recordName,annotator,C,N,N0,type)
%
%    Wrapper to WFDB RDANN:
%         http://www.physionet.org/physiotools/wag/rdann-1.htm
%
% NOTE: The WFDB Toolbox uses 0 based index, and MATLAB uses 1 based index.
%       Due to this difference annotation values ('ann') are shifted inside
%       this function in order to be compatible with the WFDB native
%       library. The MATLAB user should leave the indexing conversion to
%       the WFDB Toolbox.
%
% Reads a WFDB annotation and returns:
%
%
% ann
%       Nx1 vector of the ints. The time of the annotation in samples
%       with respect to the fist sample in the signals in recordName.
%       To convert this vector to a string of time stamps see WFDBTIME.
%
% type
%       Nx1 vector of the chars describing annotation type.
%
% subtype
%       Nx1 vector of the chars describing annotation subtype.
%
% chan
%       Nx1 vector of the ints describing annotation subtype.
%
% num
%       Nx1 vector of the ints describing annotation NUM.
%
% comments
%       Nx1 vector of the cells describing annotation comments.
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
% Optional Parameters are:
%
% C
%       A 1x1 integer. Read only the annotations for signal C.
% N
%       A 1x1 integer specifying the sample number at which to stop reading the
%       record file (default read all = N).
% N0
%       A 1x1 integer specifying the sample number at which to start reading the
%       annotion file (default 1 = begining of the record).
%
% type
%       A 1x1 String specifying the type of annoation to output (default is
%       empty, which get all annotations).
%
%
% Written by Ikaro Silva, 2013
% Last Modified: 8/9/2013
% Version 1.0
% Since 0.0.1
%
% %Example 1- Read a signal and annotaion from PhysioNet's Remote server:
%[tm, signal]=rdsamp('challenge/2013/set-a/a01');
%[ann]=rdann('challenge/2013/set-a/a01','fqrs');
%plot(tm,signal(:,1));hold on;grid on
%plot(tm(ann),signal(ann,1),'ro','MarkerSize',4)
%
%
%
% See also wfdbtime, wrann

persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('rdann');
end

%Set default pararamter values
% [ann,type,subtype,chan,num,comments]=rdann(recordName,annotator,C,N,N0)
inputs={'recordName','annotator','C','N','N0','type'};
outputs={'ann','type','subtype','chan','num','comments'};
N=[];
N0=[];
C=[];
type=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-a',annotator};

if(~isempty(N0) && N0>1)
    wfdb_argument{end+1}='-f';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=['s' num2str(N0-1)];
end


if(~isempty(N))
    wfdb_argument{end+1}='-t';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=['s' num2str(N-1)];
end

if(~isempty(type))
    wfdb_argument{end+1}='-p';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=type;
end

if(~isempty(C))
    wfdb_argument{end+1}='-c ';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=[num2str(C-1)];
end


%TODO: Improve the parsing of data. To avoid doing this at the ML wrapper
%level! The parsing assumes each line starts with a "[" and that not "["
%occurs at the comment.
%outputs={ann,type,subtype,chan,num,comments};
data=javaWfdbExec.execToStringList(wfdb_argument);
data=data.toArray();
N=length(data);
ann=zeros(N,1);
type=zeros(N,1);
subtype=zeros(N,1);
chan=zeros(N,1);
num=zeros(N,1);
comments=cell(N,1);
str=char(data(1));
if(~isempty(str) && strcmp(str(1),'['))
    %In this case there is a data stamp right after the timestamp such as:
    % [00:11:30.628 09/11/1989]      157     N    0    1    0
    for n=1:N
        str=char(data(n));
        C=textscan(str,'%s %s %u %s %u %u %u %[^\n\r]');
        ann(n)=C{3};
        type(n)=char(C{4});
        subtype(n)=char(C{5});
        chan(n)=C{6};
        num(n)=C{7};
        comments(n)=C(8);
    end
else
    %In this case there is only timestamp such as:
    % 0:00.355      355     N    0    0    0
    for n=1:N
        str=char(data(n));
        C=textscan(str,'%s %u %s %u %u %u %[^\n\r]');
        ann(n)=C{2};
        type(n)=char(C{3});
        subtype(n)=char(C{4});
        chan(n)=C{5};
        num(n)=C{6};
        comments(n)=C(7);
    end
end

ann=ann+1; %Convert to MATLAB indexing
type=char(type);
subtype=char(subtype);


for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end


