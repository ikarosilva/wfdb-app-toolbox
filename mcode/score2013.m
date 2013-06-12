function varargout=score2013(varargin)
%
% [score1,score2]=score2014(recName,refAnn,testAnn)
%
%
% Scores the an entry to the PhysioNet 2013 Challenge (Noninvasive Fetal
% ECG). 
%
% NOTE: This function requires permission to write to the current directory
% in order to store temporary files. 
%
%Input Parameters:
% recName    
%       String specifying the binary WFDB record file.
%
% refAnn    
%       String specifying the reference binary WFDB FQRS annotation file (should 
%       be 'fqrs').
%
% testAnn    
%       String specifying the test binary WFDB FQRS annotation file.
% 
% 
% Outputs:
%
% score1
%       1x1 Double preliminary results for Event 1/4.
%
% score2
%       1x1 Double preliminary results for Event 2/5.
%
% 
% NOTE: 
%    
%      1) The function requires that the all files be binary (ie, the record
%         file has a *.dat extension and *.hea header file, and the annotations files are WFDB
%         annotations, not text files).
%
%      2) All the files must be located in the directory at which this
%         function is being evaluated. You must also have write permission
%         to this directory because the scoring process generates temporary
%         files for the RR interval scoring step. These temporary filess
%         are denoted by recName.rr_refAnn and recName.rr_testAnn. If 
%         you answer is not in binary annotation format, you can use WRANN
%         to convert it to this format. 
%      
%      3) The scoring can go quicker once the RR files for the reference 
%         annotation (recName.rr_refAnn) from step (2) above has been
%         generated for the first time. If the reference annotation
%         changes for some reason, you should delete these temporary files
%         and let the function re-generate them.
%
%
% %Example :
% %Gets score for recrod 'a01.dat', with reference annotation 'a01.fqrs'
% %and user submitted answer 'a01.wfdbsample_entry1'
% [score1,score2]=score2013('a01','fqrs','wfdbsample_entry1')
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
%
% Last modified June 11, 2013
%
% See also WRANN, TACH, MXM, ANN2RR, 


persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Score2013;
end

%Set default pararamter values
inputs={'recName','refAnn','testAnn'};
outputs={'score(1)','score(2)'};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
score=javaWfdbExec.getScore({recName,refAnn,testAnn});
for n=1:nargout
        eval(['varargout{n}=' outputs{n} ';'])
end

