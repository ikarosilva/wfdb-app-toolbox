 function varargout=getWfdbClass(varargin)
%
% wfdbClass=getWfdbClass(comandName)
%
% Returns a 'wfdbClass' Java object defined my the string 'commandName' with system
% wide run time settings defined by the toolbox WFDBLOALIB file. This class will
% execute the WFDB native binary associate with 'commandName'.
%
% Written by Ikaro Silva, November 23, 2013
%         Last Modified: January 16, 2014
%
% Since 0.9.5
% See also WFDBEXEC, WFDB, WFDBLOADLIB

%endOfHelp

mlock
persistent config
if(isempty(config))
    %Add classes to dynamic path
    [~,config]=wfdbloadlib;
end

inputs={'commandName'};
outputs={'javaWfdbExec','config'};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Load the Java class in memory if it has not been loaded yet
%with system wide parameters defined by wfdbloadlib.m
javaWfdbExec=javaObject('org.physionet.wfdb.Wfdbexec',commandName,config.WFDB_CUSTOMLIB);
javaWfdbExec.setInitialWaitTime(config.NETWORK_WAIT_TIME);
javaWfdbExec.setLogLevel(config.DEBUG_LEVEL);
javaWfdbExec.setWFDB_PATH(config.WFDB_PATH);
javaWfdbExec.setWFDBCAL(config.WFDBCAL);

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end
