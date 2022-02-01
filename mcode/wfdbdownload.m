function  varargout=wfdbdownload(varargin)
%
% [success,files_saved]=wfdbdownload(recordName)
%
% Downloads a WFDB record with recordName 
% and associated files from PhysioNet server and store is on the WFDB Toolbox
% cache directory.
%
% The toolbox cache directory is determined by the following toolbox
% configuration parameters obtained by running:
%  
%  [~,config]=wfdbloadlib;
%  
%  config.CACHE     -Boolean. If true this wfdbdownlaod will attempt to
%                   download record
%
%  config.CACHE_DEST -Destination of the cached files on the user's system.
%                     It should be safe to delete the cached files, they
%                     can be re-obtained when CACHE==1.
% 
%  config.CACHE_SOURCE -Source of the cached files (default is PhysioNet's 
%                       server at https://physionet.org/data/
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
% [success,files_saved]=wfdbdownload('mitdb/1.0.0/102')
%
%
% See also WFDBLOADLIB, RDSAMP

%endOfHelp


%Set default parameter values
inputs={'recordName'};
outputs={'success','files_saved'};
success=0;
files_saved={};
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
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
        %Download single specific file if desired
        file_name=recordName(ind(end)+1:end);
        ext=file_name(findstr(file_name,'.'):end);
        timeout=600; %timeout in seconds

        if(~isempty(ext))
            [furl] = urlwrite([config.CACHE_SOURCE recordName],...
                [config.CACHE_DEST recordName],'Timeout',timeout);
            if(~isempty(furl))
                files_saved{end+1}=furl;
                warning(['Downloaded WFDB cache file: ' furl])
            end
        else
            %File extensions to download
            wfdb_extensions={'.dat','.atr','.edf','.rec','.hea','.hea-','.trigger','.mat'};
            M=length(wfdb_extensions);

            %File does not exist on cache, attempt to download from server
            for m=1:M
                try
                    [furl] = urlwrite([config.CACHE_SOURCE recordName wfdb_extensions{m}],...
                        [config.CACHE_DEST recordName wfdb_extensions{m}],'Timeout',timeout);
                    % Download all files described in header
                    if strcmp(wfdb_extensions{m},'.hea')
                        fid = fopen([config.CACHE_DEST recordName wfdb_extensions{m}]);
                        while ~feof(fid)
                            tline = fgetl(fid);
                            % Find the file names
                            tline = regexp(tline,'.+?\s','match');
                            find_string = regexp(tline{1},'.*\..+?\s','match');
                            if(~isempty(find_string))
                                fn = strrep(find_string,' ','');
                                [furl] = urlwrite([config.CACHE_SOURCE db_name fn{1}],...
                                    [config.CACHE_DEST db_name fn{1}],'Timeout',timeout);
                            end
                        end
                        fclose(fid);
                    end
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
end

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';']);
end
