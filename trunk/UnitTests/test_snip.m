function [tests,pass,perf]=test_snip(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
test_string={'Fs=360;err=snip(''mitdb/100'',''100cut'',Fs*60,Fs*2*60);'};
clean_up={['delete([pwd filesep ''100cut*'']);']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);