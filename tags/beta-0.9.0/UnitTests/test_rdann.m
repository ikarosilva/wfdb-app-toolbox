function [tests,pass,perf]=test_rdann(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
  %Example 1- Read a signal and annotaion from PhysioNet's Remote server:
 tmp_str=['[tm, signal]=rdsamp(''challenge/2013/set-a/a01'');' ...
          '[ann]=rdann(''challenge/2013/set-a/a01'',''fqrs'');' ...
         ];   

%Test the examples 
test_string={tmp_str};

[tests,pass,perf]=test_wrapper(test_string,[],verbose);