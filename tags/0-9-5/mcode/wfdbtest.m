function wfdbtest(varargin)
%This script will test the installation of the WFDB Application Toolbox
%
% Written by Ikaro Silva, 2013
%
% Version 1.0
% Since 0.0.1
%
% See also wfdb, rdsamp
inputs={'verbose'};
verbose=1;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end


if(verbose)
    fprintf('***Starting test of the WFDB Application Toolbox\n')
    fprintf('\tIf you have any problems with this test, please contact: \n')
    fprintf('\t\twfdb-matlab-support@physionet.org \n\n\n')
end

fprintf('**Checking if MATLAB JVM is running...\n')
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
        str=['system(''' JVM_PATH ' -version'')'];
        display(['Running: ' str]);
        eval(str);
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

if(verbose)
    fprintf('**Testing a WFDB linked executables this system...\n')
end

cur_dir=pwd;
os_dir=findstr(config.WFDB_NATIVE_BIN,filesep);
os_dir=config.WFDB_NATIVE_BIN(os_dir(end-1)+1:end-1);
try
    eval(['cd ' config.WFDB_NATIVE_BIN filesep 'bin'])
    switch os_dir
        case 'linux-amd64'
            !export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.;./rdsamp -r mitdb/100 -t s5
        case 'windows-amd64'
            eval(['!set PATH=%PATH%;' pwd ';rdsamp.exe -r mitdb/100 -t s5'])
        case 'macosx-x86_64'
            !export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:.;./rdsamp -r mitdb/100 -t s5
        otherwise
            warning('Unsupported OS architecture!')
    end
catch
    warning('Could not run linked executable')
    warning(lasterr)
end
cd (cur_dir)

%Test 1- Test that native libraries can me run from JVM (without MATLAB)
%and that libcurl can fetch data from PhysioNet
if(verbose)
    fprintf('**Testing native library on MATLAB JVM...\n')
end
sampleLength=10000;
cur_dir=pwd;
data_dir=[config.MATLAB_PATH];
try
    [status,cmdout] = system([JVM_PATH ' -version']);
    is7=~isempty(findstr('1.7',cmdout));
    is6=~isempty(findstr('1.6',cmdout));
    cd(data_dir)
    if(is7)
        jarname=dir('wfdb-app-JVM7-*');
    elseif(is6)
        jarname=dir('wfdb-app-JVM6-*');
    else
        warning(['Unknown JVM: '  cmdout])
    end
    str=['system(''' JVM_PATH ' -cp ' jarname.name ' org.physionet.wfdb.Wfdbexec rdsamp -r mitdb/100 -t s1'')'];
    display(['Executing: ' str])
    eval(str);
catch
    if(verbose)
        warning(lasterr);
    end
end
cd(cur_dir)


%Test 2- Test2 simple queries to PhysioNet servers
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

%Test 3- Test ability to read local data and annotations
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


%Test 3- Test ability to read records from PhysioNet servers
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
