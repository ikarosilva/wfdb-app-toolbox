function varargout=wfdbexec(varargin)
%
% [output]=wfdbexec(commandName,inputArguments,logLevel)
% [nativeCommands]=wfdbexec()
%
% Executes a WFDB native command ('commandName'), with input arguments
% given by 'inputArguments', and outputs everything into a cell array
% called 'output'. The execution is done through a system call outside of
% MATLAB. If no input arguments are provided to the function, the
% output is an array list of all available native WFDB commands in this OS.
% Substantial, non-trivial text parsing maybe required for processing the
% output into a useful MATLAB numerical variable.
%
% WFDBEXEC is useful in cases where a specific command, or feature for a
% command, is not yet in implemented in the MATLAB wrapper. This function
% may be useful for those wishing to do some debugging or performance comparisons.
%
% The user should be very carefull when using this command. The user should
% be familiar with the input and output arguments of the native command
% that he/she is using. In some cases, information about the command can be
% obtained by running the command by itself, of with either '-h',
% '-help','--help' as input arguments in order to access the command help
% information. Offcourse, you can also look at the man page or source code
% for the command at http://www.physionet.org/.
%
%
%
%Required Parameters:
%
% commandName
%       String specifying the command to be called. To ge a list of
%       available WFDB commands that may be runnable by system calls run
%       this function by itself:
%               [nativeCommands]=wfdbexec();
%
%inputArguments
%       Cell array of strings specifying the inputArguments to the command.
%       Each command flag is an element on the cell array. Command flags
%       that require additional parameters should be followed by another
%       String element with the requied parameter(s). In cases you are
%       usign a command that is already implemente in a MATLAB wrapper, it
%       maybe helpful to look at that command's MATLAB code.
%
%Optional Parameters:
%
%       logLevel
%       1x1 integer that specifies the logleve (verbosity) of the execution process.
%       Options are:
%                     0 OFF (Default)
%                     1 SEVERE
%                     2 WARNING
%                     3 INFO
%                     4 FINEST
%                     5 ALL
%
%Output:
%
%output
%       Nx1 Cell array list of Strings.
%
%
% Written by Ikaro Silva, 2013
% Last Modified: January 7, 2014
% Version 0.0.1
% Since 0.9.5
%
% %Get a  list of all WFDB native executables
% nativeComands=wfdbexec()
%
% %Get help on RDSAMP
% out=wfdbexec('rdsamp',{'-h'})
%
% %Read the first five samples of a record
% %Note: This will be very inefficient because we are not buffering
% %and we are returning a list of Strings (instead of doubles and ints).
% %This is provided just as an example on how WFDBEXEC works.
% out=wfdbexec('rdsamp',{'-r','mitdb/100','-t','s5'})
%
% See also WFDB

%endOfHelp
logLevel=[];
persistent config

if(isempty(config))
    [~,config]=wfdbloadlib;
end
if(nargin==0)
    %With no arguments passed in, we provide the user a list of native
    %commands available for this OS.
    del=findstr(' ',config.WFDB_NATIVE_BIN);
    if(~isempty(del) && del(1)==1)
        config.WFDB_NATIVE_BIN(1)=[];
    end
    commandList={};
    if(ispc)
        [~,message,~] = fileattrib([config.WFDB_NATIVE_BIN '/bin/*.exec']);
        commandList=cell(length(message),1);
        for n=1:length(message)
            str=message(n).Name;
            st=strfind(str,filesep);
            if(~isempty(st))
                str=str(st(end)+1:end);
            end
            commandList(n)={str};
        end
    else
        [~,message,~] = fileattrib([config.WFDB_NATIVE_BIN '/bin/*']);
        for n=1:length(message)
            if(~message(n).directory && message(n).UserExecute)
                str=message(n).Name;
                st=strfind(str,filesep);
                if(~isempty(st))
                    str=str(st(end)+1:end);
                end
                if(isempty(strfind(str,'lib')))
                    commandList(end+1)={str};
                end
            end
        end
    end
    varargout{1}=commandList(:);
else
    if(nargin>2)
        logLevel=varargin{3};
    end
    if(~wfdbloadlib)
        %Add classes to dynamic path
        wfdbloadlib;
    end
    javaWfdbExec=org.physionet.wfdb.Wfdbexec(varargin(1),strcmp(config.customArchFlag,'true'));
    if(~isempty(logLevel))
        javaWfdbExec.setLogLevel(logLevel);
    end
    try
        %System call
        varargout{1}=cell(javaWfdbExec.execToStringList(varargin{2}).toArray);
        clear javaWfdbExec; %Clean-up to avoid leaked Java classes
    catch exception
        clear javaWfdbExec %Clean-up to avoid leaked Java classes
        rethrow(exception)
    end
    
end
