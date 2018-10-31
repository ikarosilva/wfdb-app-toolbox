function [tests,pass,perf]=test_wabp(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={['N=2000;[x,Fs,tm]=rdsamp(''slpdb/slp60'',2,N);'...
    '[endTime,dateStamp]=wfdbtime(''slpdb/slp60'',N);wabp(''slpdb/slp60'',[],endTime{1},[],2);'...
    '[ann]=rdann(''slpdb/slp60'',''wabp'');plot(tm,x);hold on;grid on;plot(tm(ann),x(ann),''or'')']};

clean_up={['delete([pwd filesep ''slpdb'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''slpdb''],''s'');';]};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);
