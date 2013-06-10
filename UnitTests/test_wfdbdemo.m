function [tests,pass,perf]=test_wfdbdemo(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
%Test the examples 
test_string={'wfdbdemo;close all;'};

[tests,pass,perf]=test_wrapper(test_string,[],verbose);