function [tests,pass,perf]=test_mat2wfdb(varargin)


 
  %Generate 3 different signals and convert them to signed 16 bit in WFDB format
str1=['N=1024;Fs=48000;tm=[0:1/Fs:(N-1)/Fs]'';adu=''V/mV/V'';' ...
    'info=''Example 1'';sig1=double(int16(linspace(-2^15,2^15,N)''));'...
    'sig2=double(int8(sin(2*pi*tm*1000).*(2^7)))./(2^7);' ...
    'sig3=(rand(N,1) > 0.97)*2 -1 + 2^16;sig=[sig1 sig2 sig3];' ...
    'mat2wfdb(sig,''Ex1'',Fs,[],adu,info);'];
  
cln1=['delete([pwd filesep ''Ex1*'']);'];

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