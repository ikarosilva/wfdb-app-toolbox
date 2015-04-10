function varargout=wrsamp(varargin)
%
% wrsamp(tm,data,fileName,Fs,gain,format)
%
%    Wrapper to WFDB WRSAMP:
%         http://www.physionet.org/physiotools/wag/wrsamp-1.htm
%
% Writes data into a WFDB compatible *.dat and *.hea files. The files will be saved at
% the current directory (if the record is in the current directory) or, if a using 
% a PhysioNet web record , a subdirectory in the current directory, with 
% the relative path determined by recordName. You can use RDSAMP to
% verify that the write was completed successfully (see example below). For
% detailed information on the parameters described below, please see:
% http://www.physionet.org/physiotools/wag/header-5.htm
% 
%
%
% LIMITATIONS: 
%        The input variables 'tm' and 'data' should be integer values.
%		 Currently the MATLAB/Octave wrappers do take into account Baseline values. 
%        Signals that have baseline values will not be converted properly to physical units.
%        You will have to edit the generated header files manually to include baseline variables and update the checksums.
%
%
% Required Parameters:
%
% tm  
%       Nx1 vector of integers representing sample index.
%
% data  
%       NxM vector of integers (M channels) that will be written to file.
%
% fileName
%
%       String specifying the file name. WRSAMP will write the signal file in 
%       the current directory as "fileName.dat", and create a header file in the 
%       current directory "fileName.hea" for the specified record.  
%
% Optional Parameters:
%
% Fs 
%       A 1x1 double specifying the sampling frequency (in samples per second per 
%       signal) for the output signals (default: 250). It affects the output header 
%       file only. This option has no effect on the output signal file, which 
%       contains one sample per signal for each line of input. 
%
% gain 
%       A 1x1 or Mx1 vector of doubles specifying gain value in A/D units per millivolt 
%       for the output signals (default: 200).  This option the output header file only. 
%       This option has no effect on the output signal file. 
%
% format
%       String specifying the signal's default format (default: "16"). For
%       information on the available WFDB formats please see:
%       http://www.physionet.org/physiotools/wag/signal-5.htm
%
%%Example- 
%%Read signal in raw units
%[signal,Fs,tm]=rdsamp('challenge/2013/set-a/a01',[],[],[],4);
%[siginfo,Fs]=wfdbdesc('challenge/2013/set-a/a01');
%%Write a copy to file
%wrsamp(tm,signal(:,1),'a01Copy',Fs(1),200,siginfo(1).Format)
%%Check that the signals match
%[signalCopy,Fs,tm]=rdsamp('a01Copy',[],[],[],4);
%err=sum(signalCopy ~= signal(:,1))
%
%
% Written by Ikaro Silva, 2013
% Last Modified: April 10, 2015
% Since 0.0.1
%
%
% See also rdsamp, wfdbdesc, mat2wfdb
%

%endOfHelp
persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('wrsamp');
end

%Set default pararamter values
inputs={'tm','data','fileName','Fs','gain','format'};
Fs=[];
gain=[];
format=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-c','-z','-o',fileName};

if(~isempty(Fs))
    wfdb_argument{end+1}='-F';
    wfdb_argument{end+1}=num2str(Fs);
end

if(~isempty(gain))
    wfdb_argument{end+1}='-G';
    wfdb_argument{end+1}=num2str(gain);
end

if(~isempty(format))
    wfdb_argument{end+1}='-O';
    wfdb_argument{end+1}=format;
end

del=repmat([' '],size(tm));
data=[num2str(tm) del num2str(data)];
javaWfdbExec.setArguments(wfdb_argument);
javaWfdbExec.execWithStandardInput(cellstr(data));

