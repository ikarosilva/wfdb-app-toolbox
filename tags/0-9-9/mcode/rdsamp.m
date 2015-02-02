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
%       Signal data type will be either in double int16 format
%       depending on the flag passed to the function (according to
%       the boolean flags below).
%
% tm
%       Nx1 vector of doubles representing the sampling intervals.
%       Depending on input flags (see below), this vector can either be a
%       vector of integers (sampling number), or a vector of elapsed time
%       in seconds  ( with up to millisecond precision only).
%
% Fs    (Optional)
%       1xM Double, sampling frequency in Hz of all the signals in the
%       record.
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
%       record file (default read all the samples = N).
% N0
%       A 1x1 integer specifying the sample number at which to start reading the
%       record file (default 1 = first sample).
%
%
% rawUnits
%       A 1x1 integer (default: 1). Returns tm and signal as vectors
%       according to the following values:
%               rawUnits=1 -returns tm ( millisecond precision only! ) and signal in physical units with 64 bit (double) floating point precision
%               rawUnits=2 -returns tm ( millisecond precision only! ) and signal in physical units with 32 bit (single) floating point  precision
%               rawUnits=3 -returns both tm and signal as 16 bit integers (short). Use Fs to convert tm to seconds.
%               rawUnits=4 -returns both tm and signal as 64 bit integers (long). Use Fs to convert tm to seconds.
%
% highResolution
%      A 1x1 boolean (default =0). If true, reads the record in high
%      resolution mode.
%
%
% Written by Ikaro Silva, 2013
% Last Modified: December 4, 2014
% Version 1.5
%
% Since 0.0.1
%
% %Example 1- Read a signal from PhysioNet's Remote server:
%[tm, signal]=rdsamp('mitdb/100',[],1000);
%plot(tm,signal(:,1))
%
%%Example 2-Read 1000 samples from 3 signals
%[tm,signal,Fs]=rdsamp('mghdb/mgh001', [1 3 5],1000);
%
%%%Example 3- Read 1000 samples from 3 signlas in single precision format
%[tm,signal,Fs]=rdsamp('mghdb/mgh001', [1 3 5],1000,[],2);
%
%
%%%Example 4- Read a multiresolution signal with 32 samples per frame
% [tm,sig] = rdsamp('drivedb/drive02',[1],[],[],[],1);
%
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
rawUnits=1;
Fs=[];
highResolution=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Remove file extension if present
if(length(recordName)>4 && strcmp(recordName(end-3:end),'.dat'))
    recordName=recordName(1:end-4);
end
if(rawUnits <3)
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

if(~isempty(signalList))
    wfdb_argument{end+1}='-s ';
    %-1 is necessary because WFDB is 0 based indexed.
    for sInd=1:length(signalList)
        wfdb_argument{end+1}=[num2str(signalList(sInd)-1)];
    end
end

if(highResolution)
    wfdb_argument{end+1}=['-H'];
    %In this case overwrite N, multiply by the maximum number of samples
    %per frame
    maxFrame=1;
    for i=1:length(siginfo)
        ind=strfind(siginfo(1).Format,'samples per frame');
        if(~isempty(ind))
           str= siginfo(1).Format(1:ind-1);
           ind2=strfind(siginfo(1).Format,'(');
           str=str(ind2+1:end);
           frm=str2num(str);
           if(frm>maxFrame)
               maxFrame=frm;
           end
        end
    end
    N=N*maxFrame;
end

if(~isempty(N))
    %Its is possible where this is not true in rare cases where
    %there is no signal length information on the header file
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=['s' num2str(N)];
    ListCapacity=N-N0;
end


if(nargout>2)
    if(isempty(siginfo))
        [siginfo,Fs]=wfdbdesc(recordName);
    end
end

switch rawUnits
    case 1
        if(~isempty(ListCapacity))
            %Ensure list capacity if information is available
            javaWfdbExec.setDoubleArrayListCapacity(ListCapacity);
        end
        data=javaWfdbExec.execToDoubleArray(wfdb_argument);
    case 2
        if(~isempty(ListCapacity))
            %Ensure list capacity if information is available
            javaWfdbExec.setFloatArrayListCapacity(ListCapacity);
        end
        data=javaWfdbExec.execToFloatArray(wfdb_argument);
    case 3
        if(~isempty(ListCapacity))
            %Ensure list capacity if information is available
            javaWfdbExec.setShortArrayListCapacity(ListCapacity);
        end
        data=javaWfdbExec.execToShortArray(wfdb_argument);
    case 4
        if(~isempty(ListCapacity))
            %Ensure list capacity if information is available
            javaWfdbExec.setLongArrayListCapacity(ListCapacity);
        end
        data=javaWfdbExec.execToLongArray(wfdb_argument);
    otherwise
        error(['Unknown rawUnits option: ' num2str(rawUnits)])
end

if(config.inOctave)
    data=java2mat(data);
end

%When reading one signal only check if Fs is correct,
%because it may not be for multiresolution signals
if(length(signalList)==1 && rawUnits<3 )
    Fstest=1/(data(2,1)-data(1,1));
    err=abs(Fs-Fstest);
    if(err>1)
        warning([ 'Sampling frequency maybe incorrect! ' ...
            'Switching from ' num2str(Fs) ' to: ' num2str(Fstest)])
        Fs=Fstest;
    end
end

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
    
    %Perform minor data integrity check by validating with the expected
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


