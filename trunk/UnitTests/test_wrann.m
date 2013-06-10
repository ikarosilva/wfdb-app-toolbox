function [tests,pass,perf]=test_wrann(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end


%Test the examples 
test1_str=[ '[ann,type,subtype,chan,num]=rdann(''challenge/2013/set-a/a01'',''fqrs'');' ...
      'wrann(''challenge/2013/set-a/a01'',''test'',ann,type,subtype,chan,num);' ...
      '[ann,type,subtype,chan,num]=rdann(''challenge/2013/set-a/a01'',''fqrs'');' ...
      'wrann(''challenge/2013/set-a/a01'',''test'',ann,type,subtype,chan,num);' ...
      '[ann2,type2,subtype2,chan2,num2]=rdann(''challenge/2013/set-a/a01'',''test'',[],[],1);' ...
      'err=sum(ann ~= ann2);'];

  
test_string={test1_str};
clean_up={['delete([pwd filesep ''challenge'' filesep ''2013'' filesep ''set-a'' filesep ''*'']);' ...
          'rmdir([pwd filesep ''challenge''],''s'')']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);

 
 