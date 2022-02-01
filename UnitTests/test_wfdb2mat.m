function [tests,pass,perf]=test_wfdb2mat(varargin)


 
  %Generate 3 different signals and convert them to signed 16 bit in WFDB format
str1=['wfdb2mat(''mitdb/1.0.0/200'');[tm,signal,Fs,siginfo]=rdmat(''200m'');'...
    '[signal2,Fs2,tm2]=rdsamp(''200m'');sum(abs(signal-signal2));'];
  
cln1=['delete([pwd filesep ''200m*'']);'];
          
inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={str1};
clean_up={cln1};
      
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);
