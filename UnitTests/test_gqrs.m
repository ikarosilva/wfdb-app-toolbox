function [tests,pass,perf]=test_gqrs(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={['N=5000;gqrs(''mitdb/1.0.0/100'',N);ann=rdann(''mitdb/1.0.0/100'',''qrs'',[],N);[sig,Fs,tm]=rdsamp(''mitdb/1.0.0/100'',[],N);' ...
              'plot(tm,sig(:,1));hold on;grid on;plot(tm(ann),sig(ann,1),''ro'');close all']};
clean_up={['delete([pwd filesep ''mitdb'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''mitdb''],''s'')']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);
