function varargout=maprecord(varargin)
%
% [mapvalues,recList]=maprecord(names,executeCommand,stopTime,startTime,Nthreads)
%
% 
% Performs multithreaded batch processing of WFDB records usin the executable
% command 'executeCommand'. The MAPRECORD reads WFDB records in multithreaded mode,
% passing the data as a matrix to the standard input of 'executeCommand' 
% getting the results back as a vector for each record from the standard output of
% the 'executeCommand' (see examples below for detail). The
% 'executeCommand' should ouput Mx1 doubles for each record processed, if
% the command does not return any outputs (ie if it writes to file), than
% NaNs are returned.
%
%
% Required Parameters:
%
% names
%       If a single string, specifies a PhysioNet database name in which to 
%       do the processing. The PhysioNet database has to be a valid one as 
%       give by the ouput of PHYSIONETDB. If names is a Nx1 cell, each cell
%       should represent a record name (with the databse path) that can be 
%       read directly by RDSAMP.
%
% executeCommand
%       The full path and name of the executable installed on your system
%       that will be run on each record data. The 'executeCommand' 
%       should ouput Mx1 doubles for each record processed.
%
%
% Optional Parameters are:
%
% stopTime 
%       String specifying the stop time in WFDB format (default is end of
%       record).
%
% startTime 
%       String specifying the stop time in WFDB format (default is end of
%       record).
%
% Nthreads
%       A 1x1 integer specifying the number of threads to use for 
%       processing (between 1 and the number of processors in your system).
%        Default is the number of processor on your system. 
%
%
% Ouput parameters:
%
% mapvalues
%       A NxM matrix of doubles. Where each row is the ouput of running the
%       'executeCommand' on a single record from 'names' (N records) and
%       the columns are from obtained from the standard output 'executeCommand' 
%       (which gives Mx1 doubles for each record processed). 
%
% recList (Optional)
%       A Nx1 char array of strings correspoding to the record names
%       processed by MAPRECORD.
%        
% Written by Ikaro Silva, 2013
% Last Modified: 
% Version 1.0
%
% Since 0.9.1
%
% See also RDSAMP, PHYSIONETDB, WFDBTIME, WFDBDESC
%
% %The examples below assume you have an executable called 'max'
% %in a Linux machinhe under '/usr/lib/max' that calculates the maximum
% %value for each column in matrix and returns the ouput of each column
% %on a separate line
%%Example 1- Single thread execution of DFA on the 'aami-ec13' database
%tic;[mapvalues,recList]=maprecord('aami-ec13','/usr/lib/max',[],[],1);toc
%
% %Example 2- Maximum Multi-thread execution
%tic;[mapvalues,recList]=maprecord('aami-ec13','/usr/lib/max');toc

%endOfHelp
if(~wfdbloadlib)
    %Add classes to dynamic path
    wfdbloadlib;
end

%Set default pararamter values
inputs={'names','executeCommand','stopTime','startTime','Nthreads'};
outputs={'mapvalues','recList'};
stopTime='0';
startTime='0';
Nthreads=0; %the Java wrapper uses <1 to identify max number of Threads in parameter 
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end


%If N is empty, it is the entire dataset. We should ensure capacity
%so that the fetching will be more efficient.
mapvalues=javaMethod('start','org.physionet.wfdb.concurrent.MapRecord',...
    {names,executeCommand,num2str(Nthreads),stopTime,startTime});

if(nargout>1)
    %Get record list 
    recList=javaMethod('getRecordList','org.physionet.wfdb.concurrent.MapRecord',...
    {names,executeCommand,num2str(Nthreads),stopTime,startTime});
    recList=char(recList);
end

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end


