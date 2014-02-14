function varargout=rdsamp(varargin)
%
% [tm,signal,Fs]=rdsamp(recordName,signaList,N,N0,rawUnits,highResolution)
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
%       A 1x1 integer (default: 0). Returns tm and signal as vectors
%       according to the following values:
%               rawUnits=0 -returns tm and signal as integers in samples (signal is in DA units )
%               rawUnits=1 -returns tm and signal in physical units with double precision
%               rawUnits=2 -returns tm and signal in physical units with single precision (less memory requirements)
%               rawUnits=3 -returns tm and signal as 16 bit integers (short)
%               rawUnits=4 -returns tm and signal as 32 bit integers (long)
%
% highResolution
%      A 1x1 boolean (default =0). If true, reads the record in high
%      resolution mode.
%
%
% Written by Ikaro Silva, 2013
% Last Modified: January 15, 2014
% Version 1.1
%
% Since 0.0.1
%
% %Example 1- Read a signal from PhysioNet's Remote server:
%[tm, signal]=rdsamp('challenge/2013/set-a/a01',1,1000);
%plot(tm,signal(:,1))
%
%%Example 2- 
%[tm,signal,Fs]=rdsamp('mghdb/mgh001', [1 3 5],[],1000);
%
%%%Example 3- Read single precision data
%[tm,signal,Fs]=rdsamp('mghdb/mgh001', [1 3 5],[],100,2);
%
% See also WFDBDESC, PHYSIONETDB

%endOfHelp

persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('rdsamp');
end

%Set default pararamter values
inputs={'recordName','signalList','N','N0','rawUnits','highResolution'};
outputs={'data(:,1)','data(:,2:end)','Fs'};
signalList=[];
N=[];
N0=1;
ListCapacity=[]; %Use to pre-allocate space for reading
siginfo=[];
rawUnits=0;
Fs=[];
highResolution=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

if(~rawUnits)
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument={'-r',recordName,'-Ps','-f',['s' num2str(N0-1)]};
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
    for sInd=1:length(signalList)
    wfdb_argument{end+1}=[num2str(signalList(sInd)-1)];
    end
end

if(highResolution)
    wfdb_argument{end+1}=['-H'];
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

switch rawUnits
	case 0
		data=javaWfdbExec.execToDoubleArray(wfdb_argument);
		case 1
		data=javaWfdbExec.execToDoubleArray(wfdb_argument);
		case 2
		data=javaWfdbExec.execToFloatArray(wfdb_argument);
		case 3
		data=javaWfdbExec.execToShortArray(wfdb_argument);
		case 4
		data=javaWfdbExec.execToLongArray(wfdb_argument);
end

if(config.inOctave)
    data=java2mat(data);
end
for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
    
    %Perform mino data integrity check by validating with the expected
    %sizes
    [N,M]=size(data);
    if(~isempty(signalList) )
        sList=length(signalList);
        if(sList ~= (M-1))
           error(['Received: ' num2str(M-1) ' signals, expected: '  num2str(length(signalList))])
        end
    end
    if(~isempty(ListCapacity) && ~isnan(ListCapacity) )
        if((ListCapacity+1) ~= N )
           error(['Received: ' num2str(N) ' samples, expected: '  num2str(ListCapacity+1)])
        end
    end
end


