function [tests,pass,perf]=test_sumann(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={'report=sumann(''mitdb/1.0.0/100'',''atr'');'};
clean_up={};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);