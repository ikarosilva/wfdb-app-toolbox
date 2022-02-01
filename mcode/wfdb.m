function wfdb
% wfdb
%
% Display list of all function available for the WFDB App Toolbox.
% 
% Since 0.0.1
%
% %Example:
%  wfdb
%
% Written by Ikaro Silva 2012
%

%endOfHelp

[~,config]=wfdbloadlib;
help(config.MATLAB_PATH(1:end-1))
