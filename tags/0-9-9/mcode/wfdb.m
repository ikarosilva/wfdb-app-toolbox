function wfdb
% wfdb
%
%Display list of all function available for the WFDB App Toolbox.
% 
%Since 0.0.1
%
%%Example:
% wfdb
%
[~,config]=wfdbloadlib;
help(config.MATLAB_PATH(1:end-1))
%Display information regarding the WFDB Toolbox.
%Written by Ikaro Silva 2012


