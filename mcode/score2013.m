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
%      1) This function requires that the all files be binary (ie, the record
%         file has a *.dat extension and *.hea header file, and the annotations files are WFDB
%         annotations, not text files). To convert your text annnotation to
%         WDFB annotation run these steps (assuming you have an annotation file called a01.txt
%         for record a01.dat :
%                i. Make sure your signal records are reference
%                annotations are in WFDB format (you should have three
%                files per record, for record a01 they are : a01.dat, a01.hea, and a01.fqrs). 
%                Make sure these files are on the same directory as your
%                annotation. You can download the WFDB files from 
%                        http://www.physionet.org/challenge/2013/#data-sets
%               ii. Load your text annotation into MATLAB :
%                       ann=dlmread('a01.txt');
%              iii. Save it to a WFDB annotation, say "entry1" :
%                       wrann('a01','entry1',x)
%               iv. Score your results based on the file from step ii :
%                       score2013('a01','fqrs','entry1'
%
%      2) ***PLEASE make sure you run this on a directory that has been
%         backed up!!All the files must be located in the current directory
%         from where this function called. You must also have write permission
%         to this directory because the scoring process generates temporary
%         files for the RR interval scoring step. These temporary files
%         are denoted by recName.rr_refAnn and recName.rr_testAnn. These 
%         temporary files will be deleted when the function exists. If they 
%         remain for some reason, please remove all these temporary files 
%         otherwise the scores you receive may not be valid. 
%
%
% %Example :
% %Gets score for recrod 'a01.dat', with reference annotation 'a01.fqrs'
% %and user submitted answer 'a01.test' as in the format describe in
% %NOTE (1) above:
% [score1,score2]=score2013('a01','fqrs','test')
%
% Written by Ikaro Silva, 2013
% Last Modified: 6/13/2013
% Version 1.0
% Since 0.0.2
%
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
try
    curDir=pwd;
    score=javaWfdbExec.getScore({recName,curDir,refAnn,testAnn});
catch
    if(~isempty(strfind(lasterr,'java.lang.AssertionError')) && ...
        isempty(strfind(lasterr,'Annotation size do not match!')) )
        warning(['Could not process your input file (see NOTE item #1 on help) !! Please make sure your ' recName '.' refAnn ...
            ' and ' recName '.' testAnn ' are a binary WFDB file.' ...
            ' Your can convert from text to WFDB binary by using WRANN.'])
    elseif(~exist([recName '.dat']) || ~exist([recName '.hea']) || ~exist([recName '.fqrs']))
        fprintf(['Warning: Could not score entry because you are missing required files.\n\t' ...
            ' Make sure you have these file in your current directory: \n\t '...
        recName '.dat\n\t ' recName '.hea\n\t ' recName '.fqrs\n' ...
        'You can download the challenge files from:\n\t'  ...
        'http://www.physionet.org/challenge/2013/#data-sets\n']);
    end
    error(lasterr)
end
for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end

