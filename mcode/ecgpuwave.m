function ecgpuwave(varargin)
%
% ecgpuwave(recordName,annFileName,startTime,stopTime,qrsAnn,pflag,signalList)
%
%    Wrapper to the ECGPUWAVE binary written by Pablo Laguna (laguna@posta.unizar.es), Raimon Jan[�e], Eudald Bogatell, and David Vigo Anglada:
%         http://www.physionet.org/physiotools/wag/ecgpuw-1.htm
%
% ECGPUWAVE analyses an ECG signal from the specified record 'recordName', detecting the QRS complexes
% and locating the beginning, peak, and end of the P, QRS, and ST-T waveforms. The output of ecgpuwave
% is written as a standard WFDB-format annotation file associated
% with the specified annotator 'outputAnnFileName'.
%
% The QRS detector is based on the algorithm of Pan and Tompkins (reference 1) with some improvements that
% make use of slope information (reference 2). Optionally, QRS annotations can be provided as input (see option 'qrsAnn'),
% permitting the use of external QRS detectors such as sqrs(1) or manually-edited annotations
% (which can be created using wave(1) ). The waveform limit locator is based on the algorithm
% described in reference 3 and evaluated in references 3 and 4.
%
% The output annotation file contains PWAVE ("p") and TWAVE ("t") annotations
% that indicate the P- and T-wave peaks, as well as QRS annotations (NORMAL ("N") if generated
% by the built-in QRS detector, or copies of the input QRS annotations if these were supplied).
% ECGPUWAVE classifies each T wave as type 0 (normal), 1 (inverted), 2 (positive monophasic),
% 3 (negative monophasic), 4 (biphasic negative-positive), or 5 (biphasic positive-negative);
% this numeric classification is written into the num field of each TWAVE annotation.
% The P, QRS, and T waveform onsets and ends are marked in the output annotation file using
% WFON ("(") and WFOFF (")") annotations. The num field of each WFON and WFOFF annotation designates
% the type of waveform with which it is associated: 0 for a P wave, 1 for a QRS complex, or 2 for a T wave.
%
% WARNING: 
%   If ECGPUWAVE is used without providing an annotator file for the R peaks it relies on a Pan-Tompkins detector. 
%   This detector may not be optimized for your particular signal, and thus may need to be tuned, yielding anempty annotation
%   file. In this case, you may want to first run a QRS detector to generate an appropriate QRS annotation file, 
%   which you can then check manually prior to calling ECGPUWAVE with the
%   'qrsAnn' option described below.
%
% IMPORTANT NOTE:
%     A patch to the original Fortran source files was provided by Roberto Sassi in
%     order to compile ECGPUWAVE in 64-bit arch. This patch requires
%     compiling the source code with gfortran (g77 is not supported in gcc 4.x), which can
%     yield slighly different results. For more information please see:
%           http://www.dti.unimi.it/~sassi/software/wfdb64HowTo.htm
%
%
%
% References:
%1. Pan J and Tompkins WJ. A Real-Time QRS Detection Algorithm. IEEE Transactions on Biomedical Engineering 32(3):230-236, 1985.
%2. Laguna P. New Electrocardiographic Signal Processing Techniques: Application to Long-term Records. Ph. D. dissertation, Science Faculty, University of Zaragoza, 1990.
%3. Laguna P, Jan[�e] R, Caminal P. Automatic Detection of Wave Boundaries in Multilead ECG Signals: Validation with the CSE Database. Computers and Biomedical Research 27(1):45-60, 1994.
%4. Jan[�e] R, Blasi A, Garc[�i]a J, and Laguna P. Evaluation of an automatic threshold based detector of waveform limits in Holter ECG with the QT database. Computers in Cardiology 24:295-298 (1997; available at http://www.physionet.org/physiobank/database/qtdb/eval/ )
%
% Required Parameters:
%
% recordName
%       String specifying the name of the record to annotate with ECGPUWAVE.
%
% annFileName
%       String specifying the output file name that ECPUWAVE will store its
%       output.
%
% ecgpuwave(recordName,outputAnnFileName,startTime,stopTime,qrsAnn,pflag,signalList)
%
% Optional Parameters are:
%
% startTime
%      Either WFDB Time String or 1x1 integer specifying the sample number
%      specifying the starting location.
%
% stopTime
%      Either WFDB Time String or 1x1 integer specifying the sample number
%      specifying the ending location.
%
% qrsAnn
%       A String represengint the QRS annotation file that ECGPUWAVE should
%       use (must be in the WFDP PATH or within the current directory).
%
% pflag
%      A boolean (default = 0), if true all beats are processed, if false,
%      only normal beats are used.
%
% signalList
%     A Nx1 vector of integers specifying which signals in 'recordName' are
%     to be analyzed (default = [0].
%
% Wrapper written by Ikaro Silva, 2013
% Last Modified: May 29 , 2014
% Version 0.0.1
%
% 
% %Example - Will go into the WFDB directory of examples to load data
%curdir=pwd;
%[~,config]=wfdbloadlib;eval(['cd ' config.WFDB_JAVA_HOME filesep 'example'])
%ecgpuwave('100s','test');
%[tm,signal]=rdsamp('100s');
%pwaves=rdann('100s','test',[],[],[],'p');
%plot(tm,signal(:,1));hold on;grid on
%plot(tm(pwaves),signal(pwaves),'or')
%cd(curdir) %CD back to current directory
%
%
% Since 0.9.5
%
%
% See also WFDBDESC, PHYSIONETDB, RDANN, WRANN, SQRS, WQRS, WFDBEXEC

%endOfHelp

persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('ecgpuwave');
end

%Set default pararamter values
inputs={'recordName','annFileName','startTime','stopTime','qrsAnn','pflag','signalList'};
startTime=[];
stopTime=[];
qrsAnn=[];
pflag=[];
signalList=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-a',annFileName};

if(~isempty(startTime))
    wfdb_argument{end+1}='-f';
    wfdb_argument{end+1}=num2str(startTime-1);
end
if(~isempty(stopTime))
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=num2str(stopTime-1);
end

if(~isempty(signalList))
    wfdb_argument{end+1}='-s ';
    %-1 is necessary because WFDB is 0 based indexed.
    for sInd=1:length(signalList)
        wfdb_argument{end+1}=[num2str(signalList(sInd)-1)];
    end
end

if(~isempty(qrsAnn))
    wfdb_argument{end+1}='-i';
    wfdb_argument{end+1}=qrsAnn;
    if(~isempty(pflag))
        wfdb_argument{end+1}='-n';
        wfdb_argument{end+1}=[num2str(pflag)];
    end
end

javaWfdbExec.execToStringList(wfdb_argument);



