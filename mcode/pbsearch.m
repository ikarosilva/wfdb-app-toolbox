function pbsearch
%
% pbsearch()
%
%
% Launches PhysioNet's record search tool from within
% MATLAB's web browser.
%
%
% Written by Ikaro Silva, 2014
% Last Modified: October 8, 2014
% Version 1.0
%
% Since 0.9.8
%
% %Example - Launch MATLAB web browser at PhysioNet's record search tool
%  pbsearch
%
% See also WFDBDESC, PHYSIONETDB

%endOfHelp


web('https://archive.physionet.org/cgi-bin/pbs/pbsearch?subject=&comp_op=&sval=&name_num=&help_on=on&res_action=&sq_action=')
