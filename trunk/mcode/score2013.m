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
%       String specifying the WFDB record file.
%
% refAnn    
%       String specifying the reference WFDB FQRS annotation file (should 
%       be 'fqrs').
%
% testAnn    
%       String specifying the test WFDB FQRS annotation file.
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
% Written by Ikaro Silva, 2013
% Last Modified: -
% Version 1.0
%
%
% See also WRANN, TACH, MXM


%Set default pararamter values
inputs={'recName','refAnn','testAnn'};
outputs={'score1','score2'};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end


[hrFQRS]=tach(recName,refAnn);
[hrTEST]=tach(recName,testAnn);
score1=sqrt(mean((hrTEST-hrFQRS).^2));

[RRFQRS,tmsFQRS]=ann2rr(recName,refAnn);
[RRTEST,tmsTEST]=ann2rr(recName,refAnn);

N=length(RRFQRS);
strFQRS=cell(N+1);
strFQRS(1)={'[LWEditLog-1.0] Record ' refAnn ', annotator rr_fqrs (1000 samples/second)'};
for n=1:N-1
   strFQRS(n+1)={[num2str(RRFQRS(n)) ',=,' num2str(tmsFQRS(n))]};
end
patchann(strFQRS);

N=length(RRTEST);
strTEST=cell(N+1);
strTEST(1)={'[LWEditLog-1.0] Record ' testAnn ', annotator rr_fqrs (1000 samples/second)'};
for n=1:N-1
   strTEST(n+1)={[num2str(RRTEST(n)) ',=,' num2str(tmsTEST(n))]};
end
patchann(strTEST);

mxm(recName,refAnn,testAnn);

for n=1:nargout
        eval(['varargout{n}=' outputs{n} ';'])
end

%(ann2rr -r $REC -a fqrs -c -V | field -ox 1 2 | sed "s/x/,=,/" ) | patchann
% ( ann2rr -r $REC -a $TANN -c -V | field -ox 1 2 | sed "s/x/,=,/" ) | patchann
% mxm -r $REC -a rr_fqrs rr_${TANN} -f 0 -l score2.$$ 2>/dev/null
% 
% if [[ ! -a score2.$$ ]];
% then
%    echo "Could no score events 2/5 while running the command: "
%    echo "ann2rr -r ${REC} -a ${TANN} -c -V | field -ox 1 2 | sed "s/x/,=,/" ) | patchann
% mxm -r $REC -a rr_fqrs rr_${TANN} -f 0"
% fi
% 
% S1=`field -w 6 <score1.$$`
% S2=`tail -1 <score2.$$ | field -w 2`

function patchann(varargin)

persistent javaWfdbExec
if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('patchann');
end

inputs={'strTmp'};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
wfdb_argument={'strTmp'};
javaWfdbExec.execWithStandardInput(wfdb_argument);

