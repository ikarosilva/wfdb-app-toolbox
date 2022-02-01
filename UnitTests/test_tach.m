function [tests,pass,perf]=test_tach(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={['[hr]=tach(''challenge-2013/1.0.0/set-a/a01'',''fqrs'');' ...
             'plot(hr);grid on;hold on;close all']};

[tests,pass,perf]=test_wrapper(test_string,[],verbose);