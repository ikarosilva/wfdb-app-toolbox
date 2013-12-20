function [tests,pass,perf]=test_ecgpuwave(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
test_string={['curdir=pwd;[~,config]=wfdbloadlib;eval([''cd '' config.WFDB_JAVA_HOME filesep ''example'']);ecgpuwave(''100s'',''test''); ' ...
             '[tm,signal]=rdsamp(''100s'');pwaves=rdann(''100s'',''test'',[],[],[],''p'');cd(curdir);if(size(pwaves)<1);error(''failed'');end']};
clean_up={['curdir=pwd;[~,config]=wfdbloadlib;eval([''cd '' config.WFDB_JAVA_HOME filesep ''example'']);ecgpuwave(''100s'',''test'');' ...
          'delete(''100s.test'');cd(curdir);']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);
