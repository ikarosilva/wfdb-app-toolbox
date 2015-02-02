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
%       NxT vector of the chars describing annotation type. Usually
%       (but not always) T is 1.
%
% subtype
%       Nx1 vector of the chars describing annotation subtype.
%       For a list of standard annotation codes used by PhyioNet, please see:
%             http://www.physionet.org/physiobank/annotations.shtml
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
%       A 1x1 String specifying the type of annotation to output (default is
%       empty, which gets all annotations).
%
%
%
% **OPTIMIZATION NOTE: This function has been optimized for cases in which
% only the annotation sample vector is required, ie for function calls of
% the type:
%
%  ann=rdann(recordName,annotator,C,N,N0,type);
%
%  For these cases, no string parsing is required and the formatting is
%  done at the Java level, increasing substantially the processing speed.
%
%
%
% Written by Ikaro Silva, 2013
% Last Modified: December 4, 2014
% Version 2
% Since 0.0.1
%
% %Example 1- Read a signal and annotation from PhysioNet's Remote server:
%[tm, signal]=rdsamp('challenge/2013/set-a/a01');
%[ann]=rdann('challenge/2013/set-a/a01','fqrs');
%plot(tm,signal(:,1));hold on;grid on
%plot(tm(ann),signal(ann,1),'ro','MarkerSize',4)
%
%%Example 2- Read annotation from the first 500 samples only
% ann=rdann('mitdb/100','atr',[],500);
%
%
%%Example 3- Read only a certain type of annotation
% annV=rdann('mitdb/100', 'atr', [],[],[],'V');
%
%
% See also wfdbtime, wrann

%endOfHelp

persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('rdann');
    [~,config]=wfdbloadlib;
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

%Remove file extension if present
if(length(recordName)>4 && strcmp(recordName(end-3:end),'.dat'))
    recordName=recordName(1:end-4);
end

wfdb_argument={'-r',recordName,'-a',annotator};

if(~isempty(N0) && N0>1)
    
    %-1 is necessary because WFDB is 0 based indexed.
    %RDANN expects timestamp, so convert from sample to timestamp
    start_time=wfdbtime(recordName,N0-1);
    if(~isempty(start_time{end}))
        wfdb_argument{end+1}='-f';
        wfdb_argument{end+1}=[start_time{1}];
    else
        error(['Could not get record header information to find start time.'])
    end
    
end


if(~isempty(N))
    %-1 is necessary because WFDB is 0 based indexed.
    %RDANN expects timestamp, so convert from sample to timestamp
    end_time=wfdbtime(recordName,N-1);
    if(~isempty(end_time{end}))
        wfdb_argument{end+1}='-t';
        wfdb_argument{end+1}=[end_time{1}];
    else
        error(['Could not get record header information to find stop time.'])
    end
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


if(nargout ==1)
    %Optmize the parsing for cases in which we are interested only in the sample number
    %annotation values
    ann=javaWfdbExec.execToDoubleArray(wfdb_argument);
    if(config.inOctave)
        ann=java2mat(ann);
    end
    ann=ann(:,1);
else
    
    %TODO: Improve the parsing of data. To avoid doing this at the ML wrapper
    %level! The parsing assumes each line starts with a "[" and that not "["
    %occurs at the comment.
    %outputs={ann,type,subtype,chan,num,comments};
    dataJava=javaWfdbExec.execToStringList(wfdb_argument);
    data=dataJava.toArray();
    N=length(data);
    ann=zeros(N,1);
    type=[];             % Size to be defined at runtime
    subtype=char(zeros(N,1));
    chan=zeros(N,1);
    num=zeros(N,1);
    comments=cell(N,1);
    str=char(data(1));
    if(~isempty(strfind(str,'init: can''t open header for record')))
        error(str)
    end
    if(~isempty(str) && strcmp(str(1),'['))
        %In this case it is possible that there is a data stamp
        % right after the timestamp such as:
        % [00:11:30.628 09/11/1989]      157     N    0    1    0
        % but not always, the following case is also possible:
        % [00:11:30.628]      157     N    0    1    0
        %
        % So we remove the everything between [ * ]  prior to parsing
        for n=1:N
            str=char(data(n));
            if(~isempty(str))
                del_str=findstr(str,']');
                str(1:del_str)=[];
                C=textscan(str,'%u %s %s %u %u %[^\n\r]');
                ann(n)=C{1};
                if(isempty(type))
                    T=size(C{2},2);
                    type=zeros(N,T);
                end
                CN=length(char(C{2}));
                type(n,1:CN)=char(C{2});
                try
                    subtype(n)=C{3}{:};
                catch
                    warning(['Ignoring annotation subtype. Annotation subtype has multiple characters: ' ...
                        C{3}{:}]);
                    subtype(n)='0';
                end
                try
                    chan(n)=C{4}+1;%Convert to MATLAB indexing
                catch
                    warning(['Ignoring channel label. Channel label has multiple characters: ' ...
                        C{4}]);
                    chan(n)='0';
                end
                if(~isempty(C{5}))
                    num(n)=C{5};
                end
                if(~isempty(C{6}))
                    comments(n)=C(6);
                end
            end
        end
    else
        %In this case there is only timestamp such as:
        % 0:00.355      355     N    0    0    0
        str=data(1);
        if(~isempty(strfind(str,['annopen: can''t read annotator'])))
            error(str)
        end
        for n=1:N
            str=char(data(n));
            if(~isempty(str))
                if(config.inOctave)
                    C= textscan(str,'%s %u %s %s %u %u %s');
                else
                    C= textscan(str,'%s %u %s %s %u %u %[^\n\r]');
                end
                ann(n)=C{2};
                if(isempty(type))
                    T=size(C{3}{:},2);
                    type=zeros(N,T);
                end
                CN=length(C{3}{:});
                type(n,1:CN)=C{3}{:};
                try
                    subtype(n)=C{4}{:};
                catch
                    warning(['Ignoring annotation subtype. Annotation subtype has multiple characters: ' ...
                        C{4}{:}]);
                    subtype(n)='0';
                end
                try
                    chan(n)=C{5}+1;%Convert to MATLAB indexing
                catch
                    warning(['Ignoring channel label. Channel label has multiple characters: ' ...
                        C{5}]);
                    chan(n)='0';
                end
                if(~isempty(C{6}))
                    num(n)=C{6};
                end
                if(~isempty(C{7}))
                    comments(n)=C(7);
                end
            end
        end
    end
    type=char(type);
end

ann=ann+1; %Convert to MATLAB indexing



for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end


