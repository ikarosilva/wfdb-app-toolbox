function [tests,pass,perf]=test_sortann(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={['sortann(''mitdb/1.0.0/100'',''atr'',[],[],''sortedATR'');' ...
               'ann=rdann(''mitdb/1.0.0/100'',''sortedATR'');']};

clean_up={['delete([pwd filesep ''mitdb'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''mitdb''],''s'');';]};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);