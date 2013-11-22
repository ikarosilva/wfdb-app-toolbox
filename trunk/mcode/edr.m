function varargout=edr(varargin)
%
% edr(recordName,annotationFileName,win,signaList,outputAnnotator)
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
% %Note!!: This example will generate a subdirectory called mitdb
% %in your current directory. This is where the QRS and EDR annotations 
% %will be stored and read relative to the current directory
% 
% display('Generating SQRS annotation...')
% sqrs('mitdb/100');
% display('Generating EDR annotation...')
% edr('mitdb/100','qrs');
% display('Reading EDR annotation...')
%[ann,type,subtype,chan,num]=rdann('mitdb/100','edr');
%display('Ploting Normalized ECG and EDR signals')
%[tm,signal]=rdsamp('mitdb/100',[],3000);
%num(ann>3000)=[];ann(ann>3000)=[];
%plot(tm(1:3000),signal(1:3000,1)./max(signal(:,1)));hold on;grid on
%plot(tm(ann),num/max(num),'ro-');
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
inputs={'recordName','annotationFileName','win','signaList','outputAnnotator'};
outputs={''};
signalList=[];
win=[];
outputAnnotator=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-i',annotationFileName};

if(~isempty(win))
    wfdb_argument{end+1}='-d ';
    wfdb_argument{end+1}=[num2str(win(1))];
    wfdb_argument{end+1}=[num2str(win(2))];
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

javaWfdbExec.execToStringList(wfdb_argument);



