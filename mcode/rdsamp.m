function varargout=rdsamp(varargin)
%
% [tm,signal,Fs]=rdsamp(recordName,signaList,N,N0,rawUnits)
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
% Fs    (Optional)
%       1x1 Double, sampling frequency in Hz of the first signal in signalList
%       (default =1).
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
% Last Modified: June 24, 2013
% Version 1.0
%
% Since 0.0.1
%
% %Example 1- Read a signal from PhysioNet's Remote server:
%[tm, signal]=rdsamp('challenge/2013/set-a/a01',1,1000);
%plot(tm,signal(:,1))
%
%
% See also WFDBDESC, PHYSIONETDB

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
outputs={'data(:,1)','data(:,2:end)','Fs'};
signalList=[];
N=[];
N0=1;
ListCapacity=[]; %Use to pre-allocate space for reading
siginfo=[];
rawUnits=0;
Fs=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

if(~rawUnits)
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument={'-r',recordName,'-ps','-f',['s' num2str(N0-1)]};
else
    wfdb_argument={'-r',recordName,'-f',['s' num2str(N0-1)]};
end

%If N is empty, it is the entire dataset. We should ensure capacity
%so that the fetching will be more efficient.
if(isempty(N))
    [siginfo,~]=wfdbdesc(recordName);
    if(~isempty(siginfo))
        N=siginfo(1).LengthSamples;
    else
        warning('Could not get signal information. Attempting to read signal without buffering.')
    end
end

if(~isempty(N))
    %Its is possible where this is not true in rare cases where
    %there is no signal length information on the header file
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=['s' num2str(N)];
    ListCapacity=N-N0;
end

if(~isempty(ListCapacity))
    %Ensure list capacity if information is available
    javaWfdbExec.setDoubleArrayListCapacity(ListCapacity);
end

if(~isempty(signalList))
    wfdb_argument{end+1}='-s ';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=[num2str(signalList-1)];
end
if(nargout>2)
    if(isempty(siginfo))
        [siginfo,~]=wfdbdesc(recordName);
    end
    if(~isempty(siginfo))
    %Its is possible where this is not true in rare cases where
    %there is no signal length information on the header file
        if(isempty(signalList))
            Fs=siginfo(1).SamplingFrequency;
        else
            Fs=siginfo(signalList(1)).SamplingFrequency;
        end
        Fs=str2double(regexprep(Fs,'Hz',''));
    end
end

data=javaWfdbExec.execToDoubleArray(wfdb_argument);
for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end


