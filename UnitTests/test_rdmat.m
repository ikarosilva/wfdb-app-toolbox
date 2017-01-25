function [tests,pass,perf]=test_rdmat(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end


%Test the examples 
test1_str=['wfdb2mat(''mitdb/200'');' ...
           '[tm,signal,Fs,siginfo]=rdmat(''200m'');'...
           '[signal2,Fs2,tm2]=rdsamp(''200m'');' ...
           'if(sum(abs(signal-signal2)) ~=0);error(''data reading failed'');end' ...
           ];
 
test_string={test1_str};
clean_up={['delete([pwd filesep ''mitdb'' filesep ''*'']);' ...
          'if(exist([pwd filesep ''mitdb''],''dir''));rmdir([pwd filesep ''mitdb''],''s'');end;' ...
          'delete([pwd filesep ''200m*'']);' ...
          ]};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);

 
 
