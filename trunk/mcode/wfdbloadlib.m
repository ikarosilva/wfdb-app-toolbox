function [varargout]=wfdbloadlib(varargin)
%
% [isloaded,config]=wfdbloadlib(debugLevel)
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
%
% Written by Ikaro Silva, 2013
%
% Since 0.0.1
%

WFDB_APP_ML_VERSION='Beta';
inputs={'debugLevel'};
debugLevel=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

persistent per_isloaded;
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
        wfdb_path=[wfdb_path 'wfdb-app-JVM6-0-9-3.jar'];
    elseif(~isempty(strfind(ml_jar_version,'Java 1.7')))
        wfdb_path=[wfdb_path 'wfdb-app-JVM7-0-9-3.jar'];
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
            config.WFDB_APP_ML_VERSION=WFDB_APP_ML_VERSION;
            config.MAILTO='wfdb-matlab-support@physionet.org';
        end
        eval(['varargout{n}=' outputs{n} ';'])
end
