function varargout=physionetdb(varargin)
%
% db_list=physionetdb(db_name)
%
%
% Lists all the available databases at PhysioNet
% (http://physionet.org/physiobank/) or list all available signal in a database.
% Users can read the signals (waveforms) or annotations (labels) using the WFDB
% App Toolbox's functions such as RDSAMP. Options are
%
% Optional Input Parameters:
% db_name
%          String specifying the datbase to query for available signals.
%          If left empty (default) a list of available database names is
%          returned. NOTE: Some databases (such as 'mimic2db') have a huge
%          number of records so that querying the records in the database
%          can take a long time.
%
%
% Output Parameters
% db_list -(Optional) Cell array list of elements. If an output
%          is not provided, results are displayed to the screen.
%          The returned valued are either a list of database names to query
%          (if db_name is empty), or a list of available signals that can
%          be read via RDSAMP (if db_name is a name of a valid database as
%          given by the return list when db_name is empty).
%
% Author: Ikaro Silva, 2013
% Since: 0.0.1
%
% Example:
%
% %Example 1 - List all available databases from PhysioNet into the screen
% physionetdb
%
% %Example 2- List all available signals in the ucddb database.
% physionetdb('ucddb')
%

persistent isloaded

if(isempty(isloaded) || ~isloaded)
    %Add classes to path
    isloaded=wfdbloadlib;
end

inputs={'db_name'};
db_name=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

if(isempty(db_name))
    list=javaMethod('main','org.physionet.wfdb.physiobank.PhysioNetDB');
    if(nargout>0)
        db_list={};
        for i=0:double(list.size)-1
            db_list(end+1)=cell(list.get(i).getDBInfo);
        end
        varargout(1)={db_list};
    else
        for i=0:double(list.size)-1
            fprintf(char(list.get(i).getDBInfo))
            fprintf('\n');
        end
    end
else
    J=org.physionet.wfdb.physiobank.PhysioNetDB(db_name);
    if(nargout>0)
        rec_list=J.getDBRecordList;
        db_list={};
        for i=0:double(rec_list.size)-1
            sig_list=rec_list.get(i).getSignalList;
            for j=0:double(sig_list.size)-1
                db_list(end+1)=cell(sig_list.get(j).getRecordName);
            end
        end
        varargout(1)={db_list};
    else
        J.printDBRecordList
    end
end
