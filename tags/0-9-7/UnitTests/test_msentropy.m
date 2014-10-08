function [tests,pass,perf]=test_msentropy(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
test1_str=['[RR,tms]=ann2rr(''nsr2db/nsr047'',''ecg'');[y,scale]=msentropy(RR(1:1000));'];
test_string={test1_str}; 

clean_up={['']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);