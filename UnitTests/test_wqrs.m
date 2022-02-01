function [tests,pass,perf]=test_wqrs(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end


%Test the examples 
test_string={'wqrs(''challenge-2013/1.0.0/set-a/a01'');'};
clean_up={['delete([pwd filesep ''challenge-2013'' filsep ''1.0.0'' filesep ''set-a'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''challenge-2013''],''s'')']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);