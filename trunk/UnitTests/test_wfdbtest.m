function [tests,pass,perf]=test_wfdbtest(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
%Sounds redundant, I know, but wfdbtest is used for remote installation
%debugging, it has a  nice suite of test not in the function examples.
%Should be one the first tests run (or for a light check of the toolbox).
test_string={'wfdbtest(0);close all'};
[tests,pass,perf]=test_wrapper(test_string,[],verbose);