function varargout=rdmimic2wave(varargin)
%
% [tm,signal,Fs,recList,sigInfo]=rdmimic2wave(subjectID,clinicalTimeStamp,dataType,beginMinute,endMinute)
%
%
%
% Output Parameters:
%
% tm
%       Nx1 vector of doubles representing time in minutes if a match is
%       found, otherwise tm is empty. The time of the first index is an offset 
%       from beginMinute. So that the total duration in minutes is:
%
%       tm(end) - tm(1) = endMinute - beginMinute
%
%       And the time of the clinical event (clinicalTimeStamp) in the waveform signal is given by
%       (to the closest minute):
%
%       timeStamp = tm(1) + beginMinute
%
%
% signal
%       NxM vector of doubles representing the signals from dataType that
%       match the timeStamp. If no match is found an empty matrix is
%       returned.
%
% Optional Output:
%
% Fs
%       A 1x1 double representing the sampling frequency (in Hz).
%
% recList
%       A Lx1 double specifying a list of valid subjectIDs  or matched record. You can use this
%       field to find which IDs are in the matched waveform list (see below). If the
%       subjectID is defined in the function signature, recList will be
%       equal to the first found matched record if it exists.
%
%
% sigInfo
%       A Mx1 structure containing meta information about the waveforms in the 'signal' output.
%
%
% Input Parameters:
%
% subjectID
%       A 1x1 Double specifying a valid MIMIC III subject ID. For a list
%       of valid subjectID with matched waveform use this to query:
%
%       [~,~,~,recList]=rdmimic2wave([],[],dataType);
%
%       Once you have a valid subjectID and pass it to RDMIMI2WAVE, recList
%       will return the string name of the first matched record if any (empty otherwise).
%
%
% clinicalTimeStamp
%      String specifying the clinical  time of the event. This string
%      should have the following format (as described in
%       https://physionet.org/files/mimic3wdb/1.0/matched/):
%
%      'YYYY-MM-DD-hh-mm'
%
%      Where:
%           YYYY = surrogate year
%           MM = month (01-12)
%           DD = day (01-31)
%           hh = real hour (00-23)
%           mm = minute (00-59)
%
% dataType (Optional)
%     String specifying what time of high resolution waveform to fetch.
%     Options are: 'numerics' and 'waveform'. Default is 'numerics'.
%
%
% beginMinute (Optional)
%     1x1 Double specifying time in minutes of
%     how much of the signal to get before clinicalTimeStamp occurred.
%     Default is 60 minutes.
%
% endMinute (Optional)
%     1x1 Double specifying time in minutes of
%     how much of the signal to get after clinicalTimeStamp occurred.
%     Default is 60 minutes.
%
%
%
% % Example:
% [tm,signal,Fs,recList,sigInfo]=rdmimic2wave(30011,'2158-03-31-15-00',[],0,2);
% plot(tm,signal(:,2))
% title(['Found data in record: ' recList])
% legend(sigInfo(2).Description)
%
% Written by Ikaro Silva, 2013
% Last Modified: December 1, 2014
%
% Version 1.1
%
% Since 0.9.0
%
%
%
% See also RDSAMP, WFDBDESC

%endOfHelp

inputs={'subjectID','clinicalTimeStamp','dataType','beginWindow','endWindow'};
outputs={'tm','signal','Fs','recList','sigInfo'};
subjectID=[];
beginWindow=60; %beginWindow in minutes!
endWindow=60; %endWindow in minutes!
dataType='numerics';
dBName='mimic3wdb/1.0/matched/';
tm=[];
signal=[];
Fs=[];
sigInfo=[];
recList=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

persistent cachedDataType matched_id matched



if(~strcmp(cachedDataType,dataType))
    switch (dataType)
        case 'numerics'
            matched=urlread('https://physionet.org/files/mimic3wdb/1.0/matched/RECORDS-numerics');
            %case 'all'
            % Dont want to mess around with mixed sample rates yet...
            %%matched=urlread('https://physionet.org/files/mimic3wdb/1.0/matched/RECORDS');
        case 'waveform'
            matched=urlread('https://physionet.org/files/mimic3wdb/1.0/matched/RECORDS-waveforms');
        otherwise
            error(['Unknow dataType. Options are: ''numerics'', ''all'', or ''waveform''']);
    end
    cachedDataType=dataType;
    
    %Get patient ID list
    matched_id=regexprep(regexp(matched,'(p\d\d\d\d\d\d)','match'),'p','');
    for n=1:length(matched_id)
        matched_id{n}=str2num(matched_id{n});
    end
    matched_id=unique(cell2mat(matched_id));
    
   recList=matched_id; 

    
end

if(isempty(subjectID))
    %In this case the user is just querying for a list of matched
    %records
    recList=matched_id;
    for n=1:nargout
        eval(['varargout{n}=' outputs{n} '']);
    end
    return
    
end
    
%Convert timestamp to serial data (in days)
dateFormat='yyyy-mm-dd-HH-MM';
clinicalDateNum=datenum(clinicalTimeStamp,dateFormat);

%Window to include before and after the measurement (in days)
beginTime=clinicalDateNum - (beginWindow/(60*24));
endTime=clinicalDateNum + (endWindow/(60*24));


%If id exists loop through the files to see if any file is within the
%specific time range of the clinical event
matched_pid=find(matched_id==subjectID,1);
if(~isempty(matched_pid))
    
    %Get all records that match the patient and search for a record
    %that includes the clinical time
    strSubjectID=sprintf('%05d',subjectID);
    eval(['recs=regexp(matched,''p0' strSubjectID(1) '/p0' strSubjectID '.+?\n'',''match'',''all'');']);
    
    N=length(recs);
    for n=1:N
        
        recName=regexprep(recs(n),'[\n\r]+',''); %File name
        thisTimeStamp=regexp(recName,'p\d\d\d\d\d\d-','end');
        if(isempty(recName{1}))
            %Empty name, keep moving...
           continue; 
        end
        
        thisTimeStamp=recName{1,1}(1,thisTimeStamp{1}+1:end);
        if(strcmp(thisTimeStamp(end),'n'))
            thisTimeStamp(end)=[];
        end
        
        %Convert to datenum
        thisDateNum=datenum(thisTimeStamp,dateFormat);
  
        %Continue if this record started at or before beginTime
        if(thisDateNum <= beginTime)
            
            %Get record length and check its duration
            recList=[dBName recName{:}];
            sigInfo=wfdbdesc(recList);
            Fs=sigInfo(1).SamplingFrequency;
            waveLengthSamples=sigInfo(1).LengthSamples;
            
            %Get the starting/ending offsets in samples wrt the beginning of
            %the waveform
            start_offset=round(Fs*(beginTime-thisDateNum)*24*60*60) + 1;
            end_offset=round(Fs*(endTime-thisDateNum)*24*60*60) + 1;
    
            if(end_offset <= waveLengthSamples)
                %Found a match. Get the waveform and exit the the search
                %Get signal and exit
                [signal,Fs,tm]=rdsamp(recList,[],end_offset,start_offset);
                break;
            end
        end %of thisDateNum< beginTime
    end %of matched record subject
end


for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';']);
end








