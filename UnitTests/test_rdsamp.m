function [tests,pass,perf]=test_rdsamp(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
test1_str=['[tm,signal,Fs]=rdsamp(''mghdb/mgh001'', [1 3 5],1000);'];
test2_str=['[tm, signal]=rdsamp(''challenge/2013/set-a/a01'',1,1000);'...
    'plot(tm,signal(:,1));close all'];
test_string={test1_str,test2_str}; 

clean_up={['delete([pwd filesep ''mghdb'' filesep ''mgh001'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''mghdb''],''s'');'] ...
          ['%do nothing for second test']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);