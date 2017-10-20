function varargout=rdsamp(varargin)
%
% [signal,Fs,tm]=rdsamp(recordName,signaList,N,N0,rawUnits,highResolution)
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
% Fs    (Optional)
%       1xM Double, sampling frequency in Hz of all the signals in the
%       record.
%
%% tm   (Optional)
%       Nx1 vector of doubles representing the sampling intervals.
%       Depending on input flags (see below), this vector can either be a
%       vector of integers (sampling number), or a vector of elapsed time
%       in seconds  ( with up to millisecond precision only).
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
%       A 1x1 integer (default: 0). Returns tm and signal as vectors
%       according to the following values:
%               rawUnits=0 - Uses Java Native Interface to directly fetch  data, returning signal in physical units with double precision.
%               rawUnits=1 -returns tm ( millisecond precision only! ) and signal in physical units with 64 bit (double) floating point precision
%               rawUnits=2 -returns tm ( millisecond precision only! ) and signal in physical units with 32 bit (single) floating point  precision
%               rawUnits=3 -returns both tm and signal as 16 bit integers (short). Use Fs to convert tm to seconds.
%               rawUnits=4 -returns both tm and signal as 64 bit integers (long). Use Fs to convert tm to seconds.
%
% highResolution
%      A 1x1 boolean (default =0). If true, reads the record in high
%      resolution mode. Ignored if rawUnits == 0. 
%
%
% Written by Ikaro Silva, 2013
% Last Modified: April 3, 2015
% Version 2.0
%
% Since 0.0.1
%
% %Example 1- Read a signal from PhysioNet's Remote server:
%[signal,Fs,tm]=rdsamp('mitdb/100',[],1000);
%plot(tm,signal(:,1))
%
%%Example 2-Read 1000 samples from 3 signals
%[signal,Fs,tm]=rdsamp('mghdb/mgh001', [1 3 5],1000);
%
%%%Example 3- Read 1000 samples from 3 signlas in single precision format
%[signal,Fs,tm]=rdsamp('mghdb/mgh001', [1 3 5],1000,[],2);
%
%
%%%Example 4- Read a multiresolution signal with 32 samples per frame
% [sig,Fs,tm] = rdsamp('drivedb/drive02',[1],[],[],[],1);
%
%
% See also WFDBDESC, PHYSIONETDB, WFDBDOWNLOAD

%endOfHelp

persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('rdsamp');
end

%Set default pararamter values
inputs={'recordName','signalList','N','N0','rawUnits','highResolution'};
outputs={'signal','Fs','tm'};
signalList=[];
N=[];
N0=0;
ListCapacity=[]; %Use to pre-allocate space for reading
siginfo=[];
rawUnits=0;
Fs=[];
tm=[];
signal=[];
highResolution=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Cache record
wfdbdownload(recordName);
javaWfdbRdsamp=[];
if(isempty(javaWfdbRdsamp) && (rawUnits ==0))
    javaWfdbRdsamp=javaObject('org.physionet.wfdb.jni.Rdsamp');
end


%Remove file extension if present
if(length(recordName)>4 && strcmp(recordName(end-3:end),'.dat'))
    recordName=recordName(1:end-4);
end

%Initialize wfdb_argument
if((rawUnits >=3) || (rawUnits ==0) )
    %Reads raw data as integer (JNI converts to double later on)
    wfdb_argument={'-r',recordName};
else
    wfdb_argument={'-r',recordName,'-Ps'};
end

if(N0 ~=0)
   %Set start sample 
   wfdb_argument{end+1}='-f';
   wfdb_argument{end+1}=['s' num2str(N0-1)];
end

%If N is empty, it is the entire dataset. We should ensure capacity
%so that the fetching will be more efficient.
if(isempty(N) && (rawUnits ~=0))
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

if(highResolution && (rawUnits ~=0))
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
    ListCapacity=N-N0+min(1, N0);
end


if(nargout>2 && (rawUnits ~=0))
    if(isempty(siginfo))
        [siginfo,Fs]=wfdbdesc(recordName);
    end
end

switch rawUnits
    case 0
        %Use Java Native Interface wrapper
        %try
            %Channeles are returned in interleaved fashion, in a single
            %array
            data=double(conv_matrix(javaWfdbRdsamp.exec(wfdb_argument)));
        %catch
        %    javaWfdbRdsamp.reset();%Free JNI resources    
        %    error(['Could not find record: ' recordName '. Search path is set to: ''' config.WFDB_PATH '''']); 
        %end
        if(isempty(data))
           error(['Could not find record: ' recordName '. Search path is set to: ''' config.WFDB_PATH '''']); 
        end
        baseline=double(conv_matrix(javaWfdbRdsamp.getBaseline));
        gain=javaWfdbRdsamp.getGain;
        Fs=double(javaWfdbRdsamp.getFs);
        N=javaWfdbRdsamp.getNSamples;
        javaWfdbRdsamp.reset();%Free JNI resources
        M=length(baseline);
        if(~isnumeric(N))
            N=length(data)/M;
        end
        signal=zeros(N,M);
        %Convert to Physical units
        for m=1:M
           signal(:,m)= (data(m:M:end)-baseline(m))./gain(m); 
        end
        if(nargout>2)
            %generate time in seconds
             tm=linspace(0,(N-1)/Fs,N)';
        end
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
    data=conv_matrix(data);
end

if(rawUnits ~=0)
    %Remap variables to output variables (if not using JNI interface)
    signal=data(:,2:end);
    if(nargout>2)
        tm=data(:,1);
        Fstest=1/(tm(2)-tm(1)); %Not exatly accurate because tm is accurate only the millisecond
    else
        Fstest=Fs;
    end
    data=[];
    [N,M]=size(signal);
end

%When reading one signal only check if Fs is correct,
%because it may not be for multiresolution signals
if(length(signalList)==1 && rawUnits<3 && (rawUnits ~= 0) )
    err=abs(Fs-Fstest);
    if(err>1)siginfo
        warning([ 'Sampling frequency maybe incorrect! ' ...
            'Switching from ' num2str(Fs) ' to: ' num2str(Fstest)])
        Fs=Fstest;
    end
end

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
    
    %Perform minor data integrity check by validating with the expected
    %sizes
    if(~isempty(signalList) )
        sList=length(signalList);
        if(sList ~= (M))
            error(['Received: ' num2str(M) ' signals, expected: '  num2str(length(signalList))])
        end
    end
    if(~isempty(ListCapacity) && ~isnan(ListCapacity) )
        if((ListCapacity) ~= N )
            warning(['Received: ' num2str(N) ' samples, expected: '  num2str(ListCapacity)])
        end
    end
end

end

% Convert a Java array into a matrix.
function matrix = conv_matrix(array)
    if(isnumeric(array))
        matrix=array;
    else
        matrix=java2mat(array);
        if(~isnumeric(matrix))
            if(exist('java_matrix_autoconversion','builtin'))
                java_matrix_autoconversion(1,'local');
            else
                java_convert_matrix(1,'local');
            end
            matrix=java2mat(javaObject('org.octave.Matrix',array));
        end
    end
end
