function [tests,pass,perf]=test_edr(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
 
test_string={'sqrs(''mitdb/100'');edr(''mitdb/100'',''qrs'');[ann,type,subtype,chan,num]=rdann(''mitdb/100'',''edr'');num(ann>3000)=[];'};
clean_up={['delete([pwd filesep ''mitdb'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''mitdb''],''s'')']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);