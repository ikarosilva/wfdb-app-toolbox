function [tests,pass,perf]=test_wrsamp(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end


%Test the examples 
test1_str=[ '[signal, Fs, tm]=rdsamp(''challenge/2013/set-a/a01'',[],[],[],1);' ...
            '[siginfo,Fs]=wfdbdesc(''challenge/2013/set-a/a01'');' ...
            'wrsamp(tm,signal(:,1),''a01Copy'',Fs(1),200,siginfo(1).Format);' ...
            '[signalCopy, Fs, tm]=rdsamp(''a01Copy'',[],[],[],1);' ...
            'err=sum(signalCopy ~= signal(:,1));' ];
  
test_string={test1_str};
clean_up={['delete([pwd filesep ''a01Copy*'']);']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);

 
 
