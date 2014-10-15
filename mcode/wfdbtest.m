function wfdbtest(varargin)
%This script will test the installation of the WFDB Application Toolbox
%
% Written by Ikaro Silva, 2013
%
% Last Modified: October 15, 2014
%
% Version 1.2
% Since 0.0.1
%
% See also wfdb, rdsamp

%endOfHelp
inputs={'verbose'};
verbose=1;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end


if(verbose)
    fprintf('***Starting test of the WFDB Application Toolbox\n')
    fprintf('***If you experience any issues, please see our FAQ at:\n')
    fprintf('http://physionet.org/physiotools/matlab/wfdb-app-matlab/faq.shtml\n')
end

if(usejava('jvm') )
    ROOT=[matlabroot filesep 'sys' filesep 'java' filesep 'jre' filesep];
    JVM_PATH=dir([ROOT '*']);
    rm_fl=[];
    for i=1:length(JVM_PATH)
        if(~JVM_PATH(i).isdir || strcmp(JVM_PATH(i).name,'.')|| strcmp(JVM_PATH(i).name,'..'))
            rm_fl(end+1)=i;
        end
    end
    JVM_PATH(rm_fl)=[];
    if(~isempty(JVM_PATH))
        if(ispc)
            %Use quotes to escape white space in Windows
            JVM_PATH=['"' ROOT JVM_PATH.name filesep 'jre' filesep 'bin' filesep '"java'];
        else
            JVM_PATH=[ROOT JVM_PATH.name filesep 'jre' filesep 'bin' filesep 'java'];
        end
    else
        warning(['Could not find Java runtime environment!!']);
    end
else
    warning('MATLAB JVM is not properly configured for toolbox')
end


%Print Configuration settings
if(verbose)
    fprintf('**Printing Configuration Settings:\n')
end
wfdbpath=which('wfdbloadlib');
if(verbose)
    fprintf('**\tWFDB App Toolbox Path is:\n');
    fprintf('\t\t%s\n',wfdbpath);
end
[isloaded,config]=wfdbloadlib;
nsm=fieldnames(config);
if(verbose)
    config
end

%Print warning with respect to any unsupported component
if(isempty(strfind(config.MATLAB_VERSION,'2014')) && ~config.inOctave)
    warning(['You are using an unsupported version of MATLAB: ' config.MATLAB_VERSION])
end
if(~isempty(regexp(config.osName,'macosx','once')) && isempty(regexp(config.OSVersion,'10.9','once')))
    warning(['You are using an unsupported Mac OS : ' config.MATLAB_VERSION])
    warning(['The WFDB Toolbox is only supported on Mac OS X 10.9'])
end


cur_dir=pwd;
os_dir=findstr(config.WFDB_NATIVE_BIN,filesep);
os_dir=config.WFDB_NATIVE_BIN(os_dir(end-1)+1:end-1);

sampleLength=10000;
cur_dir=pwd;
data_dir=[config.MATLAB_PATH];

%Simple queries to PhysioNet servers
%loaded properly. This should work regardless of the libcurl installation
if(verbose)
    fprintf('**Querying PhysioNet for available databases...\n')
end
db_list=physionetdb;
db_size=length(db_list);
if(verbose)
    fprintf(['\t' num2str(db_size) ...
        ' databases available for download (type ''help physionetdb'' for more info).\n'])
end

%Test ability to read local data and annotations
if(verbose)
    fprintf('**Reading local example data and annotation...\n')
end
sampleLength=10000;
cur_dir=pwd;
data_dir=[config.MATLAB_PATH filesep 'example' filesep];
fname='a01';

try
    cd(data_dir)
    [tm, signal]=rdsamp(fname,[],sampleLength);
    if(length(tm) ~= sampleLength)
        warning( ['Incomplete data! tm is ' num2str(length(tm))  ', expected: ' num2str(sampleLength)]);
    end
catch
    cd(cur_dir)
    if(strfind(lasterr,'Undefined function'))
        if(verbose)
            fprintf(['ERROR!!! Toolbox is not on the MATLAB path. Add it to MATLAB path by typing:\n ']);
            display(['addpath(''' cur_dir ''')']);
        end
    end
    str=['cd(' data_dir ');[tm, signal]=rdsamp(' fname ',[],' num2str(sampleLength) ');'];
    if(verbose)
        warning(['Failed running: ' str]);
    end
end
cd(cur_dir)


try
    cd(data_dir)
    [ann]=rdann(fname,'fqrs',[],sampleLength);
    if(isempty(ann))
        warning('Annotations are empty.');
    end
catch
    cd(cur_dir)
    warning(lasterr);
end
cd(cur_dir)

%Test 4- Test ability to write local annotations
if(verbose)
    fprintf('**Calculating maternal QRS sample data ...\n')
end
try
    cd(data_dir)
    wqrs(fname,[],[],1)
    [Mann]=rdann(fname,'wqrs',[],sampleLength);
    %Remove the generated annotation file
    delete([data_dir filesep 'a01.wqrs']);
    if(isempty(Mann))
        warning('Annotations are empty.');
    end
catch
    cd(cur_dir)
    if(verbose)
        warning(lasterr);
    end
end
cd(cur_dir)


%Test ability to read records from PhysioNet servers
if(verbose)
    fprintf('**Reading data from PhysioNet...\n')
end
sampleLength=10;
try
    %Check if record does not exist already in current directory
    recExist=[];
    try
        recExist=dir(['mghdb' filesep 'mgh001']);
    catch
        %Record does not exist, go on
    end
    if(~isempty(recExist))
        warning('Cannot test because record already exists in current directory. Delete record and repeat.')
    end
    [tm, ~]=rdsamp('mghdb/mgh001', [1],sampleLength);
    if(length(tm) ~= sampleLength)
        warning( ['Incomplete data! tm is ' num2str(length(tm))  ', expected: ' num2str(sampleLength)]);
    end
catch
    if(verbose)
        warning(lasterr);
    end
end


if(verbose)
    fprintf('***Finished testing WFDB App Toolbox!\n')
    fprintf(['***Note: You currently have access to ' num2str(db_size) ...
        ' databases for download via PhysioNet:\n\t Type ''physionetdb'' for a list of the databases or ''help physionetdb'' for more info.\n'])
end
