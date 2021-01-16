function [tests,pass,perf]=test_edr(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
% Note: This requires the Signal Processing toolbox

test_string={['signal=''fantasia/1.0.0/f1o02'';r_peaks=''ecg'';' ...
             'data_type=1;channel=2;y=edr(data_type,signal,r_peaks,[],[],[],channel);' ...
             'wfdb2mat(''fantasia/1.0.0/f1o02'');[~,signal,Fs,~]=rdmat(''f1o02m'');' ...
             'resp=signal(:,1);resp=resp-mean(resp);resp=resp*200;sec=length(resp)/Fs;' ...
             'xax=[.25:.25:sec];r=interp1(y(:,1), y(:,2), xax,''spline'');' ...
             'B=fir1(100,[.1 .5],''bandpass'');edr_filt=filtfilt(B,1,r);figure;plot(xax,edr_filt);' ...
             'hold on;plot([1:length(resp)]/Fs,resp,''r'');legend(''edr'',''respiratory signal'');' ...
             'xlabel(''time (s)'');close all']};

clean_up={['delete([pwd filesep ''f1o02m*'']);']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);
