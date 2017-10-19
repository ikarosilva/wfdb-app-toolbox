function varargout=wrann(varargin)
%
% wrann(recordName,annotator,ann,anntype,subtype,chan,num,comments)
%
%    Wrapper to WFDB WRANN:
%         http://www.physionet.org/physiotools/wag/wrann-1.htm
%
% Writes data into a WFDB annotation file. The file will be saved at the
% current directory (if the record is in the current directory) or, if a using
% a PhysioNet web record , a subdirectory in the current directory, with
% the relative path determined by recordName. The files will have the
% name 'recordName" with the 'annotator' extension. You can use RDANN to
% verify that the write was completed sucessfully (see example below).
%
%
%
% NOTE: The WFDB Toolbox uses 0 based index, and MATLAB uses 1 based index.
%       Due to this difference annotation values ('ann') are shifted inside
%       this function in order to be compatible with the WFDB native
%       library. The MATLAB user should leave the indexing conversion to
%       the WFDB Toolbox.
%
% Required Parameters:
%
% recordName
%       String specifying the name of the record in the WFDB path or
%       in the current directory.
%
% annotator
%       String specifying file extension of the annotation file to be
%       written.
%
% ann
%       Nx1 integer vector containing the sample numbers of the annotations
%       with respect to the begining of the record. Samples must be >=1.
%
% anntype
%       Nx1 (single) character vector, or single character, describing each annotation type. 
%       Default is 'N'. For a list of standard annotation codes used by PhyioNet, 
%       please see: http://www.physionet.org/physiobank/annotations.shtml
%       If the description is longer than one character, use the 'comments'
%       field.
%
% subtype
%       Nx1 integer vector, or single scalar, describing annotation subtype.
%       Default is '0'. Range must be from -128 to 127.
%
% chan
%       Nx1 integer vector, or single scalar, describing annotation CHAN. 
%       Default is 0. Range must be from 0 to 255.
%
% num
%       Nx1 integer vector, or single scalar, describing annotation NUM. 
%       Default is 0. Range must be from -128 to 127.
%
% comments
%       Nx1 or single cell of strings describing annotation comments. 
%       Default is blank {''}.
%
% Note: annType, subType, chan, num, and comments can be of dimension Nx1
% or 1x1. If they are 1x1, this function will repeat the element N times.
%
%
%%Example- Creates a *.test file in your current directory
%[ann,type,subtype,chan,num]=rdann('challenge/2013/set-a/a01','fqrs');
% wrann('challenge/2013/set-a/a01','test',ann,type,subtype,chan,num)
%
%
% %Reading the file again should give the same results
%[ann,type,subtype,chan,num]=rdann('challenge/2013/set-a/a01','fqrs');
%wrann('challenge/2013/set-a/a01','test',ann,type,subtype,chan,num);
%[ann2,type2,subtype2,chan2,num2]=rdann('challenge/2013/set-a/a01','test',[],[],1);
%err=sum(ann ~= ann2)
%
%
%
% %Example 2
%[ann,type,subtype,chan,num]=rdann('mitdb/100','atr');
%wrann('mitdb/100','test',ann,type,subtype,chan,num);
%
% Written by Ikaro Silva, 2013
% Last Modified: November 4, 2014
% Version 1.4
% Since 0.0.1
%
% See also RDANN, RDSAMP, WFDBDESC
%

%endOfHelp
persistent javaWfdbExec
if(isempty(javaWfdbExec))
    javaWfdbExec=getWfdbClass('wrann');
end

% Set default pararamter values
inputs={'recordName','annotator','ann','annType','subType','chan','num','comments'};
annType='N';
subType=0;
chan=0;
num=0;
comments={''};
% Read in input arguments
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

wfdb_argument={'-r',recordName,'-a',annotator};

% Check the main input variable ann - the annotation samples
if(any(isnan(ann(:))))
   error('Annotation array contains NaNs. Not able to write file.');
end
if (min(ann)<0)
    error('Annotation samples must be positive');
end
N=length(ann);

% Convert all the annoation to 0 based index and then to strings
ann=ann-1;
ann=num2str(reshape(ann, [], 1));


% Check all other input variables:
%   - Check data type
%   - Check input shape
%   - Convert integers to strings
%   - Extend length 1 inputs to length N 

% annType - characters
if(~ischar(annType))
    error('annType must be a character or an Nx1 character vector');
end
checksize(annType, 'annType', N);
if(length(annType)==1)
    annType=repmat(annType,[N 1]);
end

% subType, chan, and num - integers
checksize(subType, 'subType', N);
subType = num2chararray(subType, 'subType', N);

checksize(chan, 'chan', N);
chan = num2chararray(chan, 'chan', N);

checksize(num, 'num', N);
num = num2chararray(num, 'num', N);

% comments - cells
if (~iscell(comments))
    error('comments must be a 1x1 or Nx1 cell of strings');
end
checksize(comments, 'comments', N);
if(length(comments)==1)
    comments=repmat(comments,N, 1);
end

% Create the strings to feed into wrann
data=cell(N,1); % The cells storing the input strings to feed into wrann
tab=char(9);
for i=1:N
    % wrann reads in the following format:
    % HH:MM:SS.mmm   %d     %c    %d    %d    %d\t%s
    % But since it doesn't actually use the time/date, and just uses the samples,
    % put in any filler. WFDB annotation files only store samples (and possibly a fs).  
    if isempty(comments{i})
        data{i}=['--------- ' ann(i,:) ' ' annType(i) ' ' ...
        subType(i,:) ' ' chan(i,:) ' ' num(i,:)];
    else
        % Only write aux field if user specifies a non-empty string.
        data{i}=['--------- ' ann(i,:) ' ' annType(i) ' ' ...
        subType(i,:) ' ' chan(i,:) ' ' num(i,:) tab comments{i}];
    end
end

% Run the wfdb wrann executable
javaWfdbExec.setArguments(wfdb_argument);
err=javaWfdbExec.execWithStandardInput(data);
if(~isempty(strfind(err.toString,['annopen: can''t'])))
    error(char(err.toString))
end

end

% Check that the input argument dimension is consistent with the number of
% annotations. 
function [] = checksize(inputarg, argname, numannots)
    inputsize = size(inputarg);
    if ((inputsize ~= [1,1]) & (inputsize ~= [numannots,1]) & (inputsize ~= [1, numannots]))
        error(strcat(argname, ' must have length 1 or N, where N = the number of annotations.'));
    end
end


% Convert an integer scalar or integer vector into a Nx[] character array
% Raises error if input argument is not a numeric. 
function chararray = num2chararray(intarg, argname, numannots)

    if(~isnumeric(intarg))
        error(strcat(argname, ' must be an integer or an Nx1 integer vector'));
    end
    
    if(length(intarg)==1)
        chararray=repmat(num2str(intarg),[numannots 1]);
    else
        if (size(intarg) == [1, numannots])
            intarg = intarg';
        end
        chararray = num2str(intarg);
    end

end
