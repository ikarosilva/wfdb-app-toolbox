function [tests,pass,perf]=test_wfdbtime(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end


%Test the examples 
test_string={'[timeStamp,dateStamp]=wfdbtime(''challenge-2013/1.0.0/set-a/a01'',[1 10 30]);'};
[tests,pass,perf]=test_wrapper(test_string,[],verbose);