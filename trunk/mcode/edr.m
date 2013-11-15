function varargout=edr(varargin)
%
% edr(recordName,annotationFileName,win,N,N0,signaList,outputAnnotator)
%
%    Wrapper to the EDR function written by George Moody:
%         http://www.physionet.org/physiotools/edr/edr.c
%
% Estimates a respiratory signal from an ECG signa using information on the
% QRS complex. No output variable is generated in the MATLAB workspace.
% Instead, an output annotation file is generate in the current directory
% with an *.edr extension but with same input record name. In the generated *.edr
% annotation files, the 'num' field of each beat annotation is replaced by
% an EDR sample.
%
% Reference: "Derivation of respiratory signals from multi-lead ECGs", pp. 113-116, Computers in Cardiology
%1985.
%  
% Required Parameters:
%
% recordName
%       String specifying the name of the record.
%
% annotationFileName
%       String specifying the name of the annotation file in which each
%       beat (QRS complex) to be used by EDR has been labelled.
%
%
% Optional Parameters are:
%
% win
%      A 2x1 vector of double specifying the window start and end times  in
%      seconds. The default= [ 0.04 0.04], starts the estimation process
%      0.04 seconds before and 0.04 seconds after the annotated beat.
%
% N
%       A 1x1 integer specifying the sample number at which to stop reading the
%       record file (default read all = N).
% N0
%       A 1x1 integer specifying the sample number at which to start reading the
%       record file (default 1 = first sample).
%
% signaList
%       A Nx1 vector of integers specifying which ECG signals to analyze.
%
% outputAnnotator
%       A String specifying the ouput annotator name (default = 'edr').
%
%  Wrapper written by Ikaro Silva, 2013
% Last Modified: November , 2013
% Version 0.0.1
%
% Since 0.9.5
%
% %Example 1-
%[tm, signal]=rdsamp('challenge/2013/set-a/a01',1,1000);
%plot(tm,signal(:,1))
%
%
% See also WFDBDESC, PHYSIONETDB, RDANN, WRANN SQRS, WQRS

persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('edr');
end

%Set default pararamter values
inputs={'recordName','annotationFileName','win','N','N0','signaList','outputAnnotator'};
outputs={''};
signalList=[];
N=[];
N0=1;
win=[];
outputAnnotator=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-i','annotationFileName','-f',['s' num2str(N0-1)]};

if(~isempty(win))
    wfdb_argument{end+1}='-d ';
    wfdb_argument{end+1}=[num2str(win(1))];
    wfdb_argument{end+1}=[num2str(win(2))];
end

if(~isempty(N))
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=['s' num2str(N-1)]; %WFDB is 0 based indexed
end

if(~isempty(signalList))
    wfdb_argument{end+1}='-s ';
    %-1 is necessary because WFDB is 0 based indexed.
    for sInd=1:length(signalList)
    wfdb_argument{end+1}=[num2str(signalList(sInd)-1)];
    end
end

if(~isempty(outputAnnotator))
    wfdb_argument{end+1}='-o';
    wfdb_argument{end+1}=outputAnnotato;
end

javaWfdbExec.execToDoubleArray(wfdb_argument);



