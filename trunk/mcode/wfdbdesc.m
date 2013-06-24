function varargout=wfdbdesc(varargin)
%
% [siginfo,Fs]=wfdbdesc(recordName)
%
%    Wrapper to WFDB WFDBDESC:
%         http://www.physionet.org/physiotools/wag/wfdbde-1.htm
%
% Reads a WFDB record metadata and returns:
%
%
% signal
%       Nx1 vector of siginfo structures with the following fields:
%
%       LengthSamples           : Number of samples in record (integer)
%       LengthTime              : Duration of record  (String WFDB Time)
%       RecordName              : Record name (String)
%       RecordIndex             : Record Index (Integer)
%       Description             : Signal Description (String)
%       SamplingFrequency       : Sampling Frequency w/ Units (String)
%       File                    : File name (String)
%       SignalIndex             : Signal Index (Integer)
%       StartTime               : Start Time (String WFDB Time)
%       Group                   : Group (Integer)
%       AdcResolution           : Bit resolution of the singal (String)
%       AdcZero                 : Physical value for 0 ADC (double)
%       Baseline                : Physical zero level of signal (Integer)
%       CheckSum                : 16-bit checksum of all samples (Integer)
%       Format                  : WFDB's Format of the samples (String)
%       Gain                    : ADC units per physical unit (String)
%       InitialValue            : Value of sample 1 in the signal (Integer)
%
%
% Fs   (Optional)
%       Nx1 vector of doubles representing the sampling frequency of each
%       signal in Hz (if the 'SamplingFrequency' string is parsable).
%   
% Required Parameters:
%
% recorName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
%
% %Example
% siginfo=wfdbdesc('challenge/2013/set-a/a01')
%
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
%
% Since 0.0.1
% See also rdsamp

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

%Set default pararamter values
inputs={'recordName'};
outputs={'siginfo','Fs'};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

javaPhysioNetRecord=org.physionet.wfdb.physiobank.PhysioNetRecord(recordName);
Recinfo=javaPhysioNetRecord.getSignalList();

%TODO: for some reason MATLAB struct() does not convert this Java class...
%For now  looping to get all the data.
field={'LengthSamples','LengthTime','RecordName','RecordIndex','Description',...
    'SamplingFrequency','File','SignalIndex','StartTime','Group', 'AdcResolution',...
    'AdcZero','Baseline','CheckSum','Format','Gain','InitialValue'};
isnumeric=[1 0 0 1 0 0 0 1 0 1 0 1 1 1 0 0 1];

M=length(field);
siginfo=[];
Fs=zeros(Recinfo.size,1)+NaN;

for n=0:(Recinfo.size-1)
    rec=Recinfo.get(n);
    for m=1:M
        if(isnumeric(m)==1)
            eval(['siginfo(' num2str(n+1) ').' field{m} '=double(java.lang.Double.valueOf((rec.get' field{m} '.toString)));' ])
        else
            eval(['siginfo(' num2str(n+1) ').' field{m} '=char(rec.get' field{m} ');' ])
            if(strcmp(field{m},'SamplingFrequency'))
               %Attempt to parse and convert to a number
               tmpFs=siginfo(n+1).SamplingFrequency;
               try
                   Fs(n+1)=str2num(regexprep(tmpFs,'\s+Hz',''));
               catch
                   %Parsing failed, leave Fs as NaN
               end
            end
        end
    end
end

for n=1:nargout
        eval(['varargout{n}=' outputs{n} ';'])
end
