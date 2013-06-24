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
%Test 1- Test that libraries, classes, and mcode are in path and are
%loaded properly
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

%Print Configuration settings
if(verbose)
    config
end
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
        error(['Failed running: ' str]);
    end
end
cd(cur_dir)
plot(tm,signal(:,1),'r-','LineWidth',1);grid on; hold on

try
    cd(data_dir)
    [ann]=rdann(fname,'fqrs',[],sampleLength);
catch
    cd(cur_dir)
    error(lasterr);
end
cd(cur_dir)
plot(tm(ann),signal(ann,1),'bo','MarkerSize',2,'MarkerFaceColor','b',...
    'LineWidth',5)
legend('Abdominal ECG','Annotated Fetal QRS')



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
catch
    cd(cur_dir)
    if(verbose)
        error(lasterr);
    end
end
cd(cur_dir)

plot(tm(Mann),signal(Mann,1),'g^','MarkerSize',2,'MarkerFaceColor','g',...
    'LineWidth',5)
legend('Abdominal ECG','Annotated Fetal QRS','Estimated Maternal QRS')
title(['Sample Data DB: challenge/2013/set-a/'])
if(verbose)
    fprintf('***Finished testing WFDB App Toolbox!\n')
    fprintf(['***Note: You currently have access to ' num2str(db_size) ...
        ' databases for download via PhysioNet:\n\t Type ''physionetdb'' for a list of the databases or ''help physionetdb'' for more info.\n'])
end
