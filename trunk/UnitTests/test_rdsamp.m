function [tests,pass,perf]=test_rdsamp(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
test1_str=['[tm,signal,Fs]=rdsamp(''mghdb/mgh001'', [1 3 5],1000,[]);'];
test2_str=['[tm,signal,Fs]=rdsamp(''mghdb/mgh001'', [1 3 5],1000,[],2);'];
test3_str=['[tm, signal]=rdsamp(''challenge/2013/set-a/a01'',[],1000);'...
    'plot(tm,signal(:,1));close all'];
test4_str=['[tm,sig] = rdsamp(''drivedb/drive02'',[1],[],[],[],1);'];

%test3_str=['[tm2,sig2]=rdsamp(''mimic2wdb/30/3003521/3003521_0001'',[2 4 5], 30499638,30484638);'];
%test4_str=['[tm2,sig2]=rdsamp(''mimic2wdb/30/3003521/3003521_0001'',[2 4 5],[],[],2);'];
%For now avoid these test conditions from above, which still need to be
%fixed. This looks like it is an issue with reading large multi-record
%signals with N and N0 defined.

test_string={test1_str,test2_str,test3_str,test4_str}; 

clean_up={[''],[''],[''],['']};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);
 