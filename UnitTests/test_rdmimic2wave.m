function [tests,pass,perf]=test_rdmimic2wave(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={['[tm,signal,Fs,recList,sigInfo]=rdmimic2wave(32805,''2986-12-15-10-00'',[],0,2);' ...
               'plot(tm,signal(:,2));title([''Found data in record: '' recList]);'...
               'legend(sigInfo(2).Description);close all']};

[tests,pass,perf]=test_wrapper(test_string,[],verbose);