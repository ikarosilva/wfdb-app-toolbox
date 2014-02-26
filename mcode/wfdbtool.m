function varargout=wfdbtool(varargin)
%
% [stat,browser,url]=wfdbtool(recordName,N,N0,systemBrowser)
%
%  MATLAB interface to PhysioNet's LightWAVE. LightWAVE is a lightweight
%  waveform and annotation viewer and editor. You can use it to view any of
%  the recordings of physiologic signals and time series in PhysioNet,
%  together with their annotations (event markers).
%
%  NOTE: This tool is currently supported only in MATLAB 2013b or higher. On some system
%      (such as Linux) the MATLAB default browser may not worker properly
%      with LightWAVE. In this case you may want to try setting the
%      'systemBrowser' to 1 (true).
%
% Required Input Parameters:
%
% recorName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% Optional Input Parameters are:
%
% N
%       A 1x1 integer specifying the sample number at which to stop displaying the
%       record file. Default is enough samples to cover 10 seconds.
% N0
%       A 1x1 integer specifying the sample number at which to start displaying the
%       record file (default 1 = first sample).Default is beginning of
%       record.
%
% systemBrowser
%      A 1x1 boolean. If true, uses the system browser. Default = 0.
%
%
% Optional Outputs are:
%
% stat
%     A  returns the status of the web command in the variable STAT. STAT = 0 indicates successful execution. STAT = 1
%     indicates that the browser was not found. STAT = 2 indicates that the
%     browser was found, but could not be launched.
%
% browser
%     Returns a handle to the last active web browser.
%
% url
%     Returns the URL of the current location.
%
% %Example 1
%
%
% Written by Ikaro Silva, 2013
% Last Modified: October 30, 2013
% Version 1.0
%
% Since 0.9.4
%
% %Example 1- Read a signal from PhysioNet's Remote server:
%wfdbtool('challenge/2013/set-a/a01')
%
%
% See also WFDBDESC, PHYSIONETDB, RDANN, WFDBTIME

%endOfHelp

%Set default pararamter values
inputs={'recordName','N','N0','systemBrowser'};
outputs={'stat','browser','url'};
N=[];
N0=[];
systemBrowser=0;
SERVER='http://physionet.org/lightwave?db=';
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%If time is specified, convert from samples to record time in seconds
if(~isempty(N) || ~isempty(N0))
    if(isempty(N0))
        N0=0; %Default value put here for lazy initialization purposes
    end
    [~,Fs]=wfdbdesc(recordName);
    N0=round(N0/Fs);
    if(isempty(N))
        %If stop time not specified, default to 10 seconds
        N=N0+round(Fs*10);
    else
        N=N0+round(N/Fs);
    end
end


%Reformat database name into PhysioBank format
sep=strfind(recordName,'/');
db=recordName(1:sep(end)-1);
rec=recordName(sep(end)+1:end);
record_url=[SERVER db '&record=' rec];

record_url
%Launch MATLAB's web browser
if(systemBrowser)
    [stat,browser,url]=web(record_url,'-browser');
else
    [stat,browser,url]=web(record_url);
end


%Send output, if anyd
for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end


