function [tests,pass,perf]=test_rdann(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
  %Example 1- Read a signal and annotaion from PhysioNet's Remote server:
 test1_str=['[tm, signal]=rdsamp(''challenge/2013/set-a/a01'');' ...
          '[ann]=rdann(''challenge/2013/set-a/a01'',''fqrs'');' ...
         ];   

test2_str=['ann=rdann(''mitdb/100'',''atr'',[],500);'];

%Test the examples 
test_string={test1_str,test2_str};

clean_up={['%do nothing for second test'],...
          ['delete([pwd filesep ''mitdb'' filesep ''100'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''mitdb''],''s'');'] ...
          };

[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);