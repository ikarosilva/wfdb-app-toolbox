function [tests,pass,perf]=test_ann2rr(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end
%Test the examples 
test_string={'[rr,tm]=ann2rr(''challenge/2013/set-a/a01'',''fqrs'');'...
             };

[tests,pass,perf]=test_wrapper(test_string,[],verbose);