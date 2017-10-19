function [tests,pass,perf]=test_lomb(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
test_string={['[signal, Fs, tm]=rdsamp(''mitdb/100'',1);[ann]=rdann(''mitdb/100'',''atr'');[Pxx,F]=lomb([tm(ann) signal(ann)]);'...
    'plot(F,Pxx);grid on;hold on']};
clean_up={};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);
