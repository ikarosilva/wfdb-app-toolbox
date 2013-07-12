function varargout=wfdbupdate(varargin)
%
% wfdbupdates
%
%    Checks WFDB App Toolbox website to see if this version of the toolbox is up
%    to date:
%         http://physionet.org/physiotools/matlab/wfdb-app-matlab/
%
%%Example-
%  wfdbbupdate
%
%
% Written by Ikaro Silva, 2013
% Last Modified: -
% Since 0.9.0
%
%
% See also WFDB, WFDBLICENSE
%

[~,config]=wfdbloadlib;
this=urlread(['file:' config.MATLAB_PATH 'NEWS']);
updates=urlread('http://physionet.org/physiotools/matlab/wfdb-app-matlab/NEWS');

if(strcmp(this,updates))
    display(['toolbox is up-to-date'])
else
    home=urlread('http://physionet.org/physiotools/matlab/wfdb-app-matlab/');
    fprintf('***NEW WFDB App Toolbox up-dates:\n\t%s',...
        updates(1:length(updates)-length(this)+119));
    fprintf('\n');
    st=strfind(home,'<pre>');
    nd=strfind(home,'</pre>');
    if(~isempty(st) && ~isempty(nd))
        install_str=['cd(''' config.MATLAB_PATH ''');cd ..;cd ..' home(st(1)+5:nd(1)-5)];
        fprintf(['***\nTo install the updates,at the '...
            'same directory as this toolbox, enter '...
            'the foloowing commands:\n\n%%Begin Code\n\n%s\n\n%%End Code\n\n'],install_str);
    end
    
end