function [tests,pass,perf]=test_dfa(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={['gqrs(''mitdb/1.0.0/117'');[rr]=ann2rr(''mitdb/1.0.0/117'',''qrs'');' ...
              '[ln,lf]=dfa(rr);plot(ln,lf);close all']};
clean_up={['delete([pwd filesep ''mitdb'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''mitdb''],''s'')']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);