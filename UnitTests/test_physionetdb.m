function [tests,pass,perf]=test_physionetdb(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end

%Test the examples 
test_string={'x=physionetdb;' , ... 
             'x=physionetdb(''ucddb/1.0.0'');' ...
             };

[tests,pass,perf]=test_wrapper(test_string,[],verbose);
    
    

  