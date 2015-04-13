function varargout=physionetdb(varargin)
%
% db_list=physionetdb(db_name,DoBatchDownload,webBrowserFlag)
%
%
% Lists all the available databases at PhysioNet
% (http://physionet.org/physiobank/) or list all available records in a database.
% Users can read the signals (waveforms) or annotations (labels) using the WFDB
% App Toolbox's functions such as RDSAMP. Options are
%
% Optional Input Parameters:
% db_name
%          String specifying the datbase to query for available records.
%          If left empty (default) a list of available database names is
%          returned. NOTE: Some databases (such as 'mimic2db') have a huge
%          number of records so that querying the records in the database
%          can take a long time.
%
% DoBatchDownload
%          If 'db_name' is present, setting this flag to true
%          (DoBatchDownload=1), will download all records of the database
%          db_name to a subdirectory in the current directory called
%          'db_name'. Default is false. Note: requires that the user have
%          write permission to the current directory.
%
%          NOTE: This function currently does not perform any checksum in order
%          to verify that the files were dwnloaded properly.
%
% webBrowserFlag
%          Boolean. If true, displays database information in MATLAB's
%          web browser (default = 0).
%
% Output Parameters
% db_list -(Optional) Cell array list of elements. If an output
%          is not provided, results are displayed to the screen.
%          The returned valued are either a list of database names to query
%          (if db_name is empty), or a list of available records that can
%          be read via RDSAMP (if db_name is a name of a valid database as
%          given by the return list when db_name is empty).
%
% Author: Ikaro Silva, 2013
% Since: 0.0.1
% Last Modified: April 8, 2015
%
%
% %Example 1 - List all available databases from PhysioNet into the screen
% physionetdb
%
% %Example 2 - List all available databases from PhysioNet in web browser
% physionetdb([],[],1)
%
% %Example 3- List all available records in the ucddb database.
% db_list=physionetdb('ucddb')
%
% %Example 4- Download all records for database MITDB
%  physionetdb('mitdb',1);
%
% %Example 5- List all records for database MITDB on a web browser
% physionetdb('mitdb',[],1);
%

%endOfHelp

persistent isloaded config

if(isempty(isloaded) || ~isloaded)
    %Add classes to path
    [isloaded,config]=wfdbloadlib;
end
%URL to PhysioBank database in PhysioNet
PHYSIONET_URL=config.CACHE_SOURCE;
inputs={'db_name','DoBatchDownload','webBrowser'};
db_name=[];
DoBatchDownload=0;
webBrowser=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
if(webBrowser && config.inOctave)
    error('Web browser option is not available in Octave.')
end

if(isempty(db_name))
    list=javaMethod('main','org.physionet.wfdb.physiobank.PhysioNetDB');
    if(nargout>0)
        db_list={};
        for i=0:double(list.size)-1
            db_list(end+1)={list.get(i).getDBInfo};
        end
        varargout(1)={db_list};
    else
        if(webBrowser)
            web([PHYSIONET_URL 'DBS'])
        else
            for i=0:double(list.size)-1
                fprintf(char(list.get(i).getDBInfo))
                fprintf('\n');
            end
        end
    end
else
    if(DoBatchDownload)
        display(['Making directory: ' db_name ' to store record files'])
        mkdir(db_name)
    end
    rec_list={};
    if(webBrowser)
        web([PHYSIONET_URL 'pbi/' db_name])
    else
        rec_list=deblank(urlread([PHYSIONET_URL db_name '/RECORDS']));
        rec_list=regexp(rec_list,'\s','split');
        Nstr=length(rec_list);
        for i=1:Nstr
            if(DoBatchDownload)
                recName=rec_list{i};
                display(['Downloading record (' num2str(i+1) ' / ' Nstr ') : ' recName])
                [success,files_saved]=wfdbdownload([db_name '/' recName]);
            end
        end
    end
    if(nargout>0)
        varargout(1)={rec_list};
    end
end
