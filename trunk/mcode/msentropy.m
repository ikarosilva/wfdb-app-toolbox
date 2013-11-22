function varargout=msentropy(varargin)
%
% msentropy(signal,dn)
%
%    Wrapper to the Multiscale Entropy C code written by Madalena Costa (mcosta@fas.harvard.edu):
%         http://physionet.org/physiotools/mse/mse-1.htm
%
% Estimates the multi scale entropy of a signal. A tutorial on Mulsticale
% entropy is available at:
% http://www.physionet.org/physiotools/mse/tutorial/
%
% 
%
% Please cite these publications when referencing this material: 
%     Costa M., Goldberger A.L., Peng C.-K. Multiscale entropy analysis of biological signals. Phys Rev E 2005;71:021906.
%     Costa M., Goldberger A.L., Peng C.-K. Multiscale entropy analysis of physiologic time series. Phys Rev Lett 2002; 89:062102.
% 
% Also include the standard citation for PhysioNet:
%     Goldberger AL, Amaral LAN, Glass L, Hausdorff JM, Ivanov PCh, Mark RG, 
%     Mietus JE, Moody GB, Peng C-K, Stanley HE. PhysioBank, PhysioToolkit, and PhysioNet: components of a new research resource for complex physiologic signals. Circulation 101(23):e215-e220 [Circulation Electronic Pages; http://circ.ahajournals.org/cgi/content/full/101/23/e215]; 2000 (June 13)
%
% Readers of may also wish to read:
%     Costa M, Peng C-K, Goldberger AL, Hausdorff JM. Multiscale entropy analysis of human gait dynamics. Physica A 2003;330:53-60.
%
%
% Required Parameters:
%
% signal
%       Nx1 vector of doubles in which the signal entropy will be
%       calculated.
%
% Optional Parameters are:
%
% dn
%       1x1 double. Sets the scale increment to dn (1-40; default: 1).
% dm
%       1x1 double. Sets the m increment to dm (1-10; default: 1).
% dr
%       1x1 double. Sets the scale increment to dr (>0; default: 0.05).
% -i n
% Begin the analysis with row n of (each) data set. Rows are numbered beginning with 0; by default, analysis begins with row 0.
% -I n
% Stop the analysis with row n of (each) data set. By default, analysis ends at row 39999, or at the end of the data set if there are fewer rows.
% -m n
% Set the minimum m (pattern length for SampEn) to n (1-10; default: 2).
% -M n
% Set the maximum m to n (1-10; default: 2).
% -n n
% Set the maximum scale for coarse-graining to n (1-40; default: 20).
% -r n
% Set the minimum r (similarity criterion for SampEn) to n (>0; default: 0.15).
% -R n
% Set the maximum m to n (>0; default: 0.15).%
%
%
%  Wrapper written by Ikaro Silva, 2013
% Last Modified: November , 2013
% Version 0.0.1
%
% Since 0.9.5
%
% %Example 1-

%
%
% See also WFDBDESC, PHYSIONETDB, RDANN, RRANN, MAPRECORD

persistent javaWfdbExec

if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

if(isempty(javaWfdbExec))
    %Load the Java class in memory if it has not been loaded yet
    javaWfdbExec=org.physionet.wfdb.Wfdbexec('mse');
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



