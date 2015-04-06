function  varargout=wfdbdownload(varargin)
%
% [success,files_saved]=wfdbdownload(recordName)
%
% Downloads a WFDB record with recordName 
% and associated files from PhysioNet server and store is on the WFB Toolbox
% cache directory.
%
% The toolbox cache directory is determined by the foolowing toolbox
% configuation parameters obtained by running:
%  
%  [~,config]=wfdbloadlib;
%  
%  config.CACHE     -Boolean. If true this wfdbdownlaod will attempt to
%                   download record
%
%  config.CACHE_DEST -Destion of the cached files on the user's system.
%                     It shoudl be safe to delete the cached files, they
%                     can be re-obtained when CACHE==1.
% 
%  config.CACHE_SOURCE -Source of the cached files (default is PhysioNet's 
%                       server at physionet.org/physiobank/database/
%
%
% Optional output parameters:
%
% success 
%       Integer. If 0, could not download files, if -1, file already
%       exists of CACHE==0. If success>0, an integer representing the number of files
%       downloaded.
%
% files_saved
%       A cell array of string specifying the saved files full path.
%
%
%   Written by Ikaro Silva, April 6, 2015
%   Last Modified: -
%   Version 0.1
%
% Since 0.0.1
% %Example:
%[success,files_saved]=wfdbdownload('mitdb/102')
%
%
% See also WFDBLOADLIB, RDSAMP

%endOfHelp


%Set default pararamter values
inputs={'recordName'};
outputs={'success','files_saved'};
success=0;
files_saved={};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

persistent config 

if(isempty(config))
    [~,config]=wfdbloadlib;
end

%Check if file exist  already, if exists in CACHE, exit
file_info=dir([config.CACHE_DEST recordName '.*']);
ind=findstr(recordName,'/'); %If empty, not in PhysioBank DB format

if(~isempty(file_info) || isempty(ind) || (config.CACHE==0))
    success=-1;
else
    
    db_name=recordName(1:ind(end));
    db_dir=[config.CACHE_DEST db_name];
    if(~isdir(db_dir))
        mkdir(db_dir);
    end
    if(isdir(db_dir))
        %File extensions to download
        wfdb_extensions={'.dat','.atr','.edf','.rec','.hea','.hea-','.trigger','.mat'};
        M=length(wfdb_extensions);
        timeout=600; %timeout in seconds
        
        %File does not exist on cache, attempt to download from server
        for m=1:M
            try
            [furl] = urlwrite([config.CACHE_SOURCE recordName wfdb_extensions{m}],...
                [config.CACHE_DEST recordName wfdb_extensions{m}],'Timeout',timeout);
            if(~isempty(furl))
                files_saved{end+1}=furl;
                warning(['Downloaded WFDB cache file: ' furl])
            end
            catch
               %Do nothing, because some extensions will not exist 
            end
        end
        success=length(files_saved);
    end
end

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end