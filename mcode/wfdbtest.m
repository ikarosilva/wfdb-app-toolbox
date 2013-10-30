function varargout=wfdbtest
%This script will test the installation of the WFDB Application Toolbox on
%client machine.
%
% Written by Ikaro Silva, 2013
%
% Version 1.0
% Since 0.0.1
% Last Modified: October 30, 2013
%
% See also wfdb, rdsamp
outputs={'good'};
good=1;
fprintf('***Starting test of the WFDB Application Toolbox\n')
fprintf('\tIf you have any problems with this test, please contact: \n')
fprintf('\t\twfdb-matlab-support@physionet.org \n\n\n')
%Test 1- Test that libraries, classes, and mcode are in path and are
%loaded properly

fprintf('**Test 1: Printing Configuration Settings\n')
wfdbpath=which('wfdbloadlib');
fprintf('**\tWFDB App Toolbox Path is:\n');
fprintf('\t\t%s\n',wfdbpath);

try
    [isloaded,config]=wfdbloadlib;
    nsm=fieldnames(config);
    %Print Configuration settings
    config
catch
    fprintf('**\t\tError: Could not load WFDB Java classes.');
    good=0;
end

%Test 2- Test2 simple queries to PhysioNet servers
%loaded properly. This should work regardless of the libcurl installation
fprintf('**Test 2: Querying PhysioNet for available databases\n')
try
    db_list=physionetdb;
    db_size=length(db_list);
    fprintf(['\t' num2str(db_size) ...
        ' databases available for download (type ''help physionetdb'' for more info).\n'])
catch
    fprintf(['**\t\tError: ' lasterr '\n']);
    good=0;
end

%Test 3- Test ability to read local data and annotations
fprintf('** Test 3: Reading local example data and annotation...\n')
try
    sampleLength=10000;
    cur_dir=pwd;
    data_dir=[config.MATLAB_PATH filesep 'example' filesep];
    fname='a01';
    cd(data_dir)
    [tm, signal]=rdsamp(fname,[],sampleLength);
    [ann]=rdann(fname,'fqrs',[],sampleLength);
    plot(tm,signal(:,1),'r-','LineWidth',1);grid on; hold on
    plot(tm(ann),signal(ann,1),'bo','MarkerSize',2,'MarkerFaceColor','b',...
        'LineWidth',5)
    close all
catch
    cd(cur_dir)
    fprintf(['**\t\tError: ' lasterr '\n']);
    good=0;
end

%Test 4- Test ability to read local data and annotations
fprintf('** Test 4: Reading data from PhysioNet server...\n')
try
    [tm,signal,Fs]=rdsamp('mghdb/mgh001', [1 3 5],1000);
    plot(tm,signal(:,1),'r-','LineWidth',1);grid on; hold on
    close all
catch
    fprintf(['**\t\tError: ' lasterr '\n']);
    good=0;
end

fprintf('***Finished testing WFDB App Toolbox!\n')

if(nargout>0)
    for n=1:nargout
        eval(['varargout{n}=' outputs{n} ';'])
    end
end