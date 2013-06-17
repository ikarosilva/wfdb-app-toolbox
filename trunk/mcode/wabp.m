function varargout=wabp(varargin)
%
% wabp(recName,beginTime,stopTime,resample,signal)
%
%    Wrapper to WFDB WABP:
%         http://www.physionet.org/physiotools/wag/wabp-1.htm
%
% Attempts to locate arterial blood pressure (ABP) pulse waveforms in a continuous ABP signal 
% in the specified WFDB record "recName". The detector algorithm is based on analysis of the first derivative 
% of the ABP waveform. The output of WABP is an annotation file (with annotator name WABP) in which all 
% detected beats are labelled normal.
% 
% WABP can process records containing any number of signals, but it uses only one signal for ABP pulse
% detection (by default, the lowest-numbered ABP, ART, or BP signal; this can be changed using the 
% 'signal' option, see below). WABP is optimized for use with adult human ABPs. 
% It has been designed and tested to work best on signals sampled at 125 Hz. For other ABPs, it may be 
% necessary to experiment with the sampling frequency as recorded in the input record’s header file
% (see WFDBDESC ). 
%
%
%
% CITING CREDIT: To credit this function, please cite the following paper at your work:
%
% Zong, W., Heldt, T., Moody, G. B., & Mark, R. G. (2003). 
% An open-source algorithm to detect onset of arterial blood pressure pulses. 
% Computers in Cardiology 2003, 30, 259-262. IEEE. 
%
%
%Required Parameters:
%
% recName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% Optional Parameters are:
%
% beginTime (Optional)
%       String specifying the begin time in WFDB format. The
%       WFDB time format is described at
%       http://www.physionet.org/physiotools/wag/intro.htm#time.
%
% stopTime (Optional)
%       String specifying the begin time in WFDB format. The
%
% resample
%       A 1x1 boolean. If true resamples the signal to 125 Hz (default=0).
%
% singal
%       A 1x1 integer. Specify the signal index of the WFDB record to be
%       used for ABP pulse detection.
%
%
% C Source file written by Wei Zong 1998
% C Source file revised by George Moody 2010
%
% MATLAB Wrapper Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
%
% %Example - Requires write permission to current directory
%wqrs('challenge/2013/set-a/a01');


persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('wqrs');
end

%Set default pararamter values
inputs={'recordName','annotator','N','N0','signal','threshold', ...
    'findJ','powerLineFrequency','resample'};
N=[];
N0=1;
signal=[]; %use application default
threshold=[];%use application default
findJ=[];
powerLineFrequency=[];
resample=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

N0=num2str(N0-1); %-1 is necessary because WFDB is 0 based indexed.
wfdb_argument={'-r',recordName,'-f',['s' N0]};

if(~isempty(N))
    wfdb_argument{end+1}='-t';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=['s' num2str(N-1)];
end
if(~isempty(signal))
    wfdb_argument{end+1}='-s';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=num2str(signal-1);
end
if(~isempty(threshold))
    wfdb_argument{end+1}='-m';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=num2str(threshold-1);
end
if(~isempty(findJ) && findJ)
    wfdb_argument{end+1}='-j';
end

if(~isempty(powerLineFrequency))
    wfdb_argument{end+1}='-p';
    %-1 is necessary because WFDB is 0 based indexed.
    wfdb_argument{end+1}=num2str(powerLineFrequency);
end

if(~isempty(resample) && resample)
    wfdb_argument{end+1}='-R';
end

javaWfdbExec.execToStringList(wfdb_argument);
    


