function [varargout]=wfdbloadlib(varargin)
%
% [isloaded,config]=wfdbloadlib(debugLevel,networkWaitTime)
%
% Loads the WDFDB libarary if it has not been loaded already into the
% MATLAB classpath. And optionally prints configuration environment and debug information
% regarding the settings used by the classes in the JAR file.
%
% Inputs:
%
% debugLevel
%       (Optional) 1x1 integer between 0 and 5 represeting the level of debug information to output from
%       Java class when output configuration information. Level 0 (no debug information),
%       level =5 is maximum level of information output by the class (logger set to finest). Default is level 0.
%
% networkWaitTime
%       (Optional) 1x1 interger representing the longest time in
%       milliseconds  for which the JVM should wait for a data stream from
%       PhysioNet (default is =1000  , ie one second). If you need to change this time to a
%       longer value across the entire toolbox, it is better modify to default value in the source
%       code below and restart MATLAB.
%
%
% Written by Ikaro Silva, 2013
%
% Since 0.0.1
%

%%%%% SYSTEM WIDE CONFIGURATION PARAMETERS %%%%%%%
%%% Change these values for system wide configuration of the WFDB binaries

WFDB_PATH=[]; %If empty, will use the default giveng confing.WFDB_PATH
WFDBCAL=[]; %If empty, will use the default giveng confing.WFDBCAL
debugLevel=0;
networkWaitTime=1000;

%%%% END OF SYSTEM WIDE CONFIGURATION PARAMETERS






inputs={'debugLevel','networkWaitTime'};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

persistent per_isloaded wfdb_path;

if(isempty(per_isloaded))
    per_isloaded=0;
end
if(~per_isloaded)
    jar_path=which('wfdbloadlib');
    cut=strfind(jar_path,'wfdbloadlib.m');
    wfdb_path=jar_path(1:cut-1);
    
    ml_jar_version=version('-java');
    %Check if path has not been added yet
    if(~isempty(strfind(ml_jar_version,'Java 1.6')))
        wfdb_path=[wfdb_path 'wfdb-app-JVM6-0-9-5.jar'];
    elseif(~isempty(strfind(ml_jar_version,'Java 1.7')))
        wfdb_path=[wfdb_path 'wfdb-app-JVM7-0-9-5.jar'];
    else
        error(['Cannot load on unsupported JVM: ' ml_jar_version])
    end
    
    class_path=javaclasspath('-dynamic');
    if(~isempty(strfind(class_path,wfdb_path)))
        %Class already loaded!
        %warning(['WFDB classes already in path, only switching persistent variable to true.'])
        per_isloaded=1;
    else
        %Load class to dynamic class path
        %warning(['Adding WFDB classes to MATLAB''s dynamic class path.'])
        javaaddpath(wfdb_path)
        per_isloaded=1;
    end
    
end

isloaded=per_isloaded;
%version('-java')
outputs={'isloaded','config'};
for n=1:nargout
    if(n>1)
        config.MATLAB_VERSION=version;
        javaWfdbExec=org.physionet.wfdb.Wfdbexec('wfdb-config');
        javaWfdbExec.setLogLevel(debugLevel);
        config.WFDB_VERSION=char(javaWfdbExec.execToStringList('--version'));
        env=regexp(char(javaWfdbExec.getEnvironment),',','split');
        for e=1:length(env)
            tmpstr=regexp(env{e},'=','split');
            varname=strrep(tmpstr{1},'[','');
            varname=strrep(varname,' ','');
            varname=strrep(varname,']','');
            eval(['config.' varname '=''' tmpstr{2} ''';'])
        end
        config.MATLAB_PATH=strrep(which('wfdbloadlib'),'wfdbloadlib.m','');
        config.SUPPORT_EMAIL='wfdb-matlab-support@physionet.org';
        wver=regexp(wfdb_path,filesep,'split');
        config.WFDB_JAVA_VERSION=wver{end};
        config.DEBUG_LEVEL=debugLevel;
        config.NETWORK_WAIT_TIME=networkWaitTime;
        
        %Remove empty spaces from arch name
        del=strfind(config.osName,' ');
        config.osName(del)=[];
        
        %Define WFDB Environment variables
        if(isempty(WFDB_PATH))
            WFDB_PATH=['. http://physionet.org/physiobank/database'];
        end
        if(isempty(WFDBCAL))
            WFDBCAL=[config.WFDB_JAVA_HOME filesep 'database' filesep 'wfdbcal'];
        end
        config.WFDB_PATH=WFDB_PATH;
        config.WFDBCAL=WFDBCAL;
        
    end
    eval(['varargout{n}=' outputs{n} ';'])
end
