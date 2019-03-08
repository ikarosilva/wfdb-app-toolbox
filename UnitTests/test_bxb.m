function [tests,pass,perf]=test_bxb(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={['[refAnn]=rdann(''mitdb/100'',''atr'');sqrs(''mitdb/100'');'...
    '[testAnn]=rdann(''mitdb/100'',''qrs'');r=bxb(''mitdb/100'',''atr'',''qrs'',''bxbReport.txt'')']};

clean_up={['delete([pwd filesep ''mitdb'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''mitdb''],''s'');delete([pwd filesep ''bxbReport.txt'']);';]};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);