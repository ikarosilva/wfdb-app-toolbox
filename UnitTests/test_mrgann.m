function [tests,pass,perf]=test_mrgann(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={'wqrs(''mitdb/100'');mrgann(''mitdb/100'',''atr'',''wqrs'',''testAnn'')'};

clean_up={['delete([pwd filesep ''mitdb'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''mitdb''],''s'');';]};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);