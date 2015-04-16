function varargout=wfdbdesc(varargin)
%
% [siginfo,Fs,sigClass]=wfdbdesc(recordName)
%
%    Wrapper to WFDB WFDBDESC:
%         http://www.physionet.org/physiotools/wag/wfdbde-1.htm
%
% Reads a WFDB record metadata and returns:
%
%
% siginfo
%       Nx1 vector of structures with the following fields:
%
%       LengthSamples           : Number of samples in record (integer)
%       LengthTime              : Duration of record  (String WFDB Time)
%       RecordName              : Record name (String)
%       RecordIndex             : Record Index (Integer)
%       Description             : Signal Description (String)
%       SamplingFrequency       : Sampling Frequency w/ Units (String)
%       File                    : File name (String)
%       SignalIndex             : Zero Based Signal Index (Integer)
%       StartTime               : Start Time (String WFDB Time)
%       Group                   : Group (Integer)
%       AdcResolution           : Bit resolution of the signal (String)
%       AdcZero                 : Physical value for 0 ADC (double)
%       Baseline                : Physical zero level of signal (Integer)
%       CheckSum                : 16-bit checksum of all samples (Integer)
%       Format                  : WFDB's Format of the samples (String)
%       Gain                    : ADC units per physical unit (String)
%       InitialValue            : Value of sample 1 in the signal (Integer)
%       IO                      : IO Type  (String)
%
% Fs   (Optional)
%       Nx1 vector of doubles representing the sampling frequency of each
%       signal in Hz (if the 'SamplingFrequency' string is parsable).
%
% sigClass (Optional)
%       Nx1 cell array of strings for the corresponding signal class based on
%       information from PhysioNet: www.physionet.org/physiobank/signals.shtml.
%       The signal class will be one of the following:
%                    BP         blood pressure
%                    CO         cardiac output
%                    CO2        carbon dioxide
%                    ECG        electrocardiogram
%                    EEG        electroencephalogram
%                    EMG        electromyogram
%                    EOG        electrooculogram
%                    Flow       air flow
%                    HR         heart rate
%                    Noise      for stress testing
%                    O2         oxygen
%                    PLETH      plethysmogram
%                    Pos        body position
%                    Resp       respiration
%                    Sound      sound
%                    ST         ECG ST segment level
%                    Status     status of patient or monitor
%                    SV         stroke volume
%                    Temp       temperature 
%                    []         unkown class
%
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
% %Example 2 -Get signal Classes
% [siginfo,Fs,sigClass]=wfdbdesc('mitdb/100')
%
%
% Written by Ikaro Silva, 2013
% Last Modified by Ikaro Silva, April 16, 2015
%
% Version 3.0
%
% Since 0.0.1
% See also RDSAMP

%endOfHelp

persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('wfdbdesc');
end

%Set default pararamter values
inputs={'recordName'};
outputs={'siginfo','Fs','sigClass'};

for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={recordName};
data=char(javaWfdbExec.execToStringList(wfdb_argument));
lines=[1 strfind(data,',')];
siginfo=[];
Fs=[];
sigClass={};
L=length(lines);

%Define record Wide parameters
RecordName=[];
StartTime =[];
LengthSamples=[];
LengthTime=[];
SamplingFrequency =[];
Notes=[];

%index for each signal
ind=0;
for n=1:L-1
    str=(data(lines(n):lines(n+1)-1));
    str=str(2:end); %Remove comma
    if(~isempty(strfind(str,'Record')))
        C=textscan(str,'%s%s');
        RecordName=C{2}{:};
    elseif(~isempty(strfind(str,'Starting time:')))
        ind1=strfind(str,':');
        StartTime =str(ind1+2:end);
    elseif(~isempty(strfind(str,'Length:')))
        %Should happen only once
        ind1=strfind(str,'(');
        ind2=strfind(str,'sample intervals)');
        LengthSamples=str2num(str(ind1+1:ind2-1));
        C=textscan(str,'%s%s%s%s%s');
        LengthTime=C{2};
    elseif(~isempty(strfind(str,'Sampling frequency:')))
        C=textscan(str,'%s%s%u%s');
        SamplingFrequency =C{3};
    elseif(~isempty(strfind(str,'Group')))
        %In this case we are seeing a new signal, enter record wide
        %fields as well
        ind=ind+1;
        C=textscan(str,'%s%d');
        siginfo(ind).Group=C{2};
        siginfo(ind).RecordName=RecordName;
        siginfo(ind).StartTime =StartTime;
        siginfo(ind).LengthSamples=LengthSamples;
        siginfo(ind).LengthTime=LengthTime{:};
        siginfo(ind).SamplingFrequency =SamplingFrequency;
        Fs(end+1)=SamplingFrequency;
    elseif(~isempty(strfind(str,'Signal')))
        C=textscan(str,'%s%d:');
        siginfo(ind).SignalIndex=C{2};
    elseif(~isempty(strfind(str,'File:')))
        ind1=strfind(str,':');
        siginfo(ind).File=str(ind1+2:end);
    elseif(~isempty(strfind(str,'Description:')))
        ind1=strfind(str,':');
        siginfo(ind).Description=str(ind1+2:end);
    elseif(~isempty(strfind(str,'Gain:')))
        ind1=strfind(str,':');
        siginfo(ind).Gain=str(ind1+2:end);
    elseif(~isempty(strfind(str,'Initial value:')))
        C=textscan(str,'%s%s%f');
        siginfo(ind).InitialValue=C{3};
    elseif(~isempty(strfind(str,'Storage format:')))
        ind1=strfind(str,':');
        siginfo(ind).Format=str(ind1+2:end);
    elseif(~isempty(strfind(str,'I/O:')))
        ind1=strfind(str,':');
        siginfo(ind).IO=str(ind1+2:end);
    elseif(~isempty(strfind(str,'ADC resolution:')))
        ind1=strfind(str,':');
        siginfo(ind).AdcResolution=str(ind1+2:end);
    elseif(~isempty(strfind(str,'ADC zero:')))
        ind1=strfind(str,':');
        siginfo(ind).AdcZero=str2num(str(ind1+2:end));
    elseif(~isempty(strfind(str,'Baseline:')))
        C=textscan(str,'%s%f');
        siginfo(ind).Baseline=C{2};
    elseif(~isempty(strfind(str,'Checksum:')))
        C=textscan(str,'%s%f');
        siginfo(ind).CheckSum=C{2};
    else
        %Skip unused field
    end
    
end

if(nargout>2)
    %Get signal class
    sigClass=getSignalClass(siginfo,config);
end
for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end



%%%%%% Help function to return signal class information %%%%%

function sigClass=getSignalClass(siginfo,config)

persistent class_def

if(isempty(class_def))
    %Get signal class information from PhysioNet's servers
    %and store information locally ( persistent )
    class_def=urlread([config.CACHE_SOURCE '../signals.shtml']);
    st_ind=findstr(class_def,'<td><b>Description</b></td><td></td></tr>');
    class_def(1:st_ind+1)=[];
    end_ind=findstr(class_def,'</table></center>');
    class_def(end_ind:end)=[];
    class_def=regexp(class_def,'<tr>','split');
end
M=length(siginfo);
sigClass=cell(M,1);
for m=1:M
    ind=strmatch(['<td>' siginfo(m).Description '</td>'],class_def);
    if(isempty(ind))
        continue
    end
    str=regexp(class_def{ind},'</td>','split');
    str=regexprep(str{2},'<td>','');
    sigClass(m)={str};
end




