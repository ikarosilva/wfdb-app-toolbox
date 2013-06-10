function varargout=rdsamp(varargin)
%
% [tm, signal,Fs]=rdsamp(recordName,signaList,N,N0,rawUnits)
%
%    Wrapper to WFDB RDSAMP:
%         http://www.physionet.org/physiotools/wag/rdsamp-1.htm
%
% Reads a WFDB record and returns:
%
%
% signal    
%       NxM matrix (doubles) of M signals with each signal being N samples long.
%       Signal dataype will be either in double int16 format
%       depending on the flag passed to the function (according to
%       the boolean flags below).
%
% tm    
%       Nx1 vector of doubles representing the sampling intervals 
%       (elapsed time in seconds).
%
%
% Required Parameters:
%
% recorName 
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
%
% Optional Parameters are:
%
% signalList
%       A Mx1 array of integers. Read only the signals (columns)
%       named in the signalList (default: read all signals).
% N 
%       A 1x1 integer specifying the sample number at which to stop reading the 
%       record file (default read all = N).
% N0 
%       A 1x1 integer specifying the sample number at which to start reading the 
%       record file (default 1 = first sample).
%
%
% rawUnits
%
%       A 1x1 boolean (default: false=0). If true, returns tm in samples (Nx1
%       integets) and returns signal in the original DA units (NxM integers).
%
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
%
% %Example 1- Read a signal from PhysioNet's Remote server:
%[tm, signal]=rdsamp('challenge/2013/set-a/a01',1,1000);
%plot(tm,signal(:,1))
%
%
% See also wfdbdesc, wrsamp

persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('rdsamp');
end

%Set default pararamter values
inputs={'recordName','signalList','N','N0','rawUnits'};
outputs={'data(:,1)','data(:,2:end)'};
signalList=[];
N=[];
N0=1;
ListCapacity=[]; %Use to pre-allocate space for reading
rawUnits=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

N0=num2str(N0-1); %-1 is necessary because WFDB is 0 based indexed.
if(~rawUnits)
    wfdb_argument={'-r',recordName,'-ps','-f',['s' N0]};
else
    wfdb_argument={'-r',recordName,'-f',['s' N0]};
end

%If N is empty, it is the entire dataset. We should ensure capacity
%so that the fetching will be more efficient.
if(isempty(N))
    %TODO: Find size of dataset and set N equal to it
    [siginfo,~]=wfdbdesc(recordName);
    if(~isempty(siginfo))
        N=siginfo(1).LengthSamples;
    else
        warning('Could not get signal information. Attempting to read signal without buffering.')
    end
end

if(~isempty(N))
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=['s' num2str(N)];
    ListCapacity=N-N0;
end

if(isempty(ListCapacity))
    %In this case no N was given, calculate N from signal information
    %if available
    try
        siginfo=wfdbdesc(recordName);
        Nmax=siginfo(1).LengthSamples;
        ListCapacity=Nmax-N0;
        javaWfdbExec.setDoubleArrayListCapacity(ListCapacity);
    catch
        %Ignore error and dont pre-allocate space, performance may 
        %suffer a little.
    end
    
end

if(~isempty(signalList))
    wfdb_argument{end+1}='-s ';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=[num2str(signalList-1)];
end
data=javaWfdbExec.execToDoubleArray(wfdb_argument);
for n=1:nargout
        eval(['varargout{n}=' outputs{n} ';'])
end


