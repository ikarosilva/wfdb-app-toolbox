function varargout=rdann(varargin)
%
% [ann,anntype,subtype,chan,num,comments]=rdann(recordName, annotator, C, N, N0, AT)
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
%       Nx1 integer vector of the annotation locations in samples
%       with respect to the beginning of the record. 
%       To convert this vector to a string of time stamps see WFDBTIME.
%
% anntype
%       Nx1 character vector describing the annotation types.
%       For a list of standard annotation codes used by PhyioNet, see:
%             http://www.physionet.org/physiobank/annotations.shtml
%
% subtype
%       Nx1 integer vector describing annotation subtype.
%       
% chan
%       Nx1 integer vector describing annotation channel.
%
% num
%       Nx1 integer vector describing annotation NUM.
%
% comments
%       Nx1 cell of strings describing annotation comments.
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
%       An integer scalar. Return only the annotations with chan = C.
% N
%       An integer specifying the sample number at which to stop reading the
%       record file. Default read all.
% N0
%       A 1x1 integer specifying the sample number at which to start reading the
%       annotion file. Default = 1, begining of the record.
%
% AT
%       The anntype character. Return only annotations with subtype = S. 
%       Default is empty, which returns all annotations.
%
%
%
% **OPTIMIZATION NOTE: This function has been optimized for cases in which
% only the annotation sample vector is required, ie for function calls of
% the type:
%
%  ann=rdann(recordName, annotator, C, N, N0, AT);
%
%  For these cases, no string parsing is required and the formatting is
%  done at the Java level, increasing substantially the processing speed.
%
%
%
% Written by Ikaro Silva, 2013
% Last Modified: January 4, 2017
% Version 2.1
% Since 0.0.1
%
% %Example 1- Read a signal and annotation from PhysioNet's Remote server:
%[signal,Fs,tm]=rdsamp('challenge/2013/set-a/a01');
%[ann]=rdann('challenge/2013/set-a/a01','fqrs');
%plot(tm,signal(:,1));hold on;grid on
%plot(tm(ann),signal(ann,1),'ro','MarkerSize',4)
%
%%Example 2- Read annotation from the first 500 samples only
% ann=rdann('mitdb/100','atr',[],500);
%
%
%%Example 3- Read annotations with anntype = 'V' only. 
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
% [ann, anntype, subtype, chan, num, comments] = rdann(recordName, annotator, C, N, N0, AT)
inputs={'recordName','annotator','C','N','N0','AT'};
outputs={'ann','anntype','subtype','chan','num','comments'};
N=[];
N0=[];
C=[];
AT=[];
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

if(~isempty(AT))
    wfdb_argument{end+1}='-p';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=AT;
end

if(~isempty(C))
    wfdb_argument{end+1}='-c ';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=[num2str(C-1)];
end

if(nargout ==1)
    %Optmize the parsing for cases in which we are interested only in the sample number
    %annotation values
    wfdb_argument{end+1}='-e'; % Ensure first column is just elapsed time so it can be skipped. 
    ann=javaWfdbExec.execToDoubleArray(wfdb_argument);
    if(config.inOctave)
        ann=java2mat(ann);
    end
else
    
    %TODO: Improve the parsing of data. To avoid doing this at the ML wrapper
    %level! The parsing assumes each line starts with a "[" and that not "["
    %occurs at the comment.
    %outputs={ann,anntype,subtype,chan,num,comments};
    dataJava=javaWfdbExec.execToStringList(wfdb_argument);
    data=dataJava.toArray();
    N=length(data);
    ann=zeros(N,1);
    anntype=[];             % Size to be defined at runtime
    subtype=zeros(N,1);
    chan=zeros(N,1);
    num=zeros(N,1);
    comments=cell(N,1);
    str=char(data(1));
    if(~isempty(strfind(str,'init: can''t open header for record')))
        error(str)
    end
    if(~isempty(str) && strcmp(str(1),'['))
        % Absolute time stamp. Also possibly a date stamp
        % right after the timestamp such as:
        % [00:11:30.628 09/11/1989]      157     N    0    1    0
        % but not always. The following case is also possible:
        % [00:11:30.628]      157     N    0    1    0
        %
        % So we remove the everything between [ * ]  prior to parsing
        for n=1:N
            str=char(data(n));
            if(~isempty(str))
                del_str=findstr(str,']');
                str(1:del_str)=[];
                C=textscan(str,'%d %s %d %d %d',1);
                ann(n)=C{1};
                if(isempty(anntype))
                    T=size(C{2},2);
                    anntype=zeros(N,T);
                end
                CN=length(char(C{2}));
                anntype(n,1:CN)=char(C{2});  
                subtype(n)=C{3};
                chan(n)=C{4}+1;%Convert to MATLAB indexing
                
                if(~isempty(C{5}))
                    num(n)=C{5};
                end
                tabpos=findstr(str,char(9));
                if(tabpos)
                    comments{n}=str(tabpos(1)+1:end);
                end
            end
        end
    else
        %In this case there is only a relative timestamp such as:
        % 0:00.355      355     N    0    0    0
        str=data(1);
        if(~isempty(strfind(str,['annopen: can''t read annotator'])))
            error(str)
        end
        for n=1:N
            str=char(data(n));
            if(~isempty(str))
                C=textscan(str,'%s %d %s %d %d %d',1);
                ann(n)=C{2};
                if(isempty(anntype))
                    T=size(C{3}{:},2);
                    anntype=zeros(N,T);
                end
                CN=length(C{3}{:});
                anntype(n,1:CN)=C{3}{:};
                
                subtype(n)=C{4};
                chan(n)=C{5}+1;%Convert to MATLAB indexing
                
                if(~isempty(C{6}))
                    num(n)=C{6};
                end
                tabpos=findstr(str,char(9));
                if(tabpos)
                    comments{n}=str(tabpos(1)+1:end);
                end
            end
        end
    end
    anntype=char(anntype);
end

ann=ann+1; %Convert to MATLAB indexing

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end


