function [tests,pass,perf]=test_score2013(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
  %Example 1- Read a signal and annotaion from PhysioNet's Remote server:
 tmp_str=['[isloaded,config]=wfdbloadlib;data_dir=[config.MATLAB_PATH filesep ''example'' filesep];' ...
          'cd(data_dir);[s1,s1]=score2013(''a01'',''fqrs'',''entry1'');'];   

%Test the examples 
test_string={tmp_str};

[tests,pass,perf]=test_wrapper(test_string,[],verbose);