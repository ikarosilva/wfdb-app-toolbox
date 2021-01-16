function [tests,pass,perf]=test_wfdbdesc(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={'siginfo=wfdbdesc(''challenge-2013/1.0.0/set-a/a01'');'};
[tests,pass,perf]=test_wrapper(test_string,[],verbose);