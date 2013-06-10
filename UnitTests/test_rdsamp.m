function [tests,pass,perf]=test_rdsamp(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
test_string={'[tm, signal]=rdsamp(''challenge/2013/set-a/a01'',1,1000);' ...
              'plot(tm,signal(:,1));close all'};

[tests,pass,perf]=test_wrapper(test_string,[],verbose);