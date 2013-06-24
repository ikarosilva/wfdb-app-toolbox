function varargout=rdann(varargin)
%
% [ann,type,subtype,chan,num]=rdann(recordName,annotator,C,N,N0)
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
%
%
% Written by Ikaro Silva, 2013
% Last Modified: 6/13/2013
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
% [ann,type,subtype,chan,num]=rdann(recordName,annotator,C,N,N0)
inputs={'recordName','annotator','C','N','N0'};
outputs={'ann','char(data(:,2))',...
    'floor(data(:,3))','floor(data(:,4))','floor(data(:,5))'};
N=[];
N0=[];
C=[];
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
    
if(~isempty(C))
    wfdb_argument{end+1}='-c ';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=[num2str(C-1)];
end

data=javaWfdbExec.execToDoubleArray(wfdb_argument);

%TODO: Improve the parsing of data. To avoid doing this at the ML wrapper
%level
if(length(data(1,:))==6) 
    %In this case there is a data stamp right after the timestamp that did
    %not get properly parsed such as:
    % [00:11:30.628 09/11/1989]      157     N    0    1    0
    % So ignore the second column
    ann=round(data(:,2))+1; %Convert to MATLAB indexing
else
    %In this case there is only timestamp that was properly parsed by the Java such as:
    % 0:00.355      355     N    0    0    0
    ann=round(data(:,1))+1; %Convert to MATLAB indexing
end
for n=1:nargout
        eval(['varargout{n}=' outputs{n} ';'])
end


