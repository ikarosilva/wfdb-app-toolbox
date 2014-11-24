function varargout=corrint(varargin)
%
% [y1,y2,y3]=corrint(x,embeddedDim,timeLag,timeStep,distanceThreshold,neighboorSize,estimationMode,findScaling)
%
% Correlation integral analysis of a time series.
%
% Required input parameter:
% x
%       Nx1 matrix (doubles) of time series to be analyzed.
%
% Optional Parameters are:
%
% embeddedDim
%        1x1 Integer specifying the embedded dimension size to use (default
%        =2).
%
% timeLag
%       1x1 Integer specifying the minimu time lag distance (in samples) of the point to
%       be estimated. Default is 2. If timeLag=-1 the timeLag is estimated
%       from the first zero-crossing point of the autocorrelation of x.
%
% timeStep
%       1x1 Integer specifying time lag distance (in samples) within
%       each point used in the embeddedDimm vector. For example, if embeddedDim
%       is 3 and timeStep =2, then the embedded dimension vector will consists of
%       3 samples separated by 2 samples each, covering a window of size of 7 samples.
%
% distanceThreshold
%       1x1 double specifying the distance threshold between embedded
%       points. Points whos distance is less than this are considered in
%       the same neighborhood and used for either prediction, recurrence, or the
%       estimation of the embedded dimension.
%
% neighboorSize
%      1x1 Integer specifying the number of neighbors to be used for
%      prediction and smoothing (see 'estimationMode' parameter).
%
% estimationMode
%       String specifying what analysis to be done in the time series.
%       Options are:
%                       'recurrence'  -Calculates recurence data to be used
%                                      in for recurrence plots (default).
%                       'dimension'   -Generates statistics for the estimation of the correlation dimension
%                                      of the time series and it's scaling
%                                      regions.
%                       'prediction'  -Predicts second half of the time
%                                      series using the first half as a model
%                                      and neighboorSize nearest points.
%                       'smooth'      -Predicts all point of the times
%                                      series using all other points as a
%                                      model and neighboorSize nearest
%                                      points.
%
% findScaling
%      1x1 Boolean flag to be passed when using 'dimension' mode. If set to
%      true the scaling region will be searched automaticall, using
%      r1=std(x)/4 and r2 -> C(r1)/C(r2) ~ 5. Default value is false.
%
% The output returned by CORRINT is dependendent on the 'estimationMode'
% parameter, so that the description of the ooutput below is broken down into the
% different possible options for the 'estimationMode' parameter.
%
%
% Written by Ikaro Silva, 20134
% Last Modified: November 23, 2014
% Version 1.0
%
% Since 0.9.8
%
%
% See also SURROGATE, DFA, MSENTROPY

%endOfHelp

persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('corrint');
end

%Set default pararamter values
inputs={'x','embeddedDim','timeLag','timeStep','distanceThreshold','neighboorSize','estimationMode','findScaling'};
outputs={'y1','y2','y3'};
embeddedDim=[];
timeLag=[];
timeStep=[];
distanceThreshold=[];
neighboorSize=[];
estimationMode='recurrence';
findScaling=0;
wfdb_argument={};
y1=[];
y2=[];
y3=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
if(~isempty(embeddedDim))
    wfdb_argument{end+1}='-d';
    wfdb_argument{end+1}=num2str(embeddedDim);
end
if(~isempty(timeLag))
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=num2str(timeLag);
end
if(~isempty(timeStep))
    wfdb_argument{end+1}='-s';
    wfdb_argument{end+1}=num2str(timeStep);
end
if(~isempty(distanceThreshold))
    wfdb_argument{end+1}='-r';
    wfdb_argument{end+1}=num2str(distanceThreshold);
end
if(~isempty(neighboorSize))
    wfdb_argument{end+1}='-n';
    wfdb_argument{end+1}=num2str(neighboorSize);
end

switch estimationMode
    case 'recurrence'
        wfdb_argument{end+1}='-p';
    case 'dimension'
        wfdb_argument{end+1}='-v';
        y3=' ';
        if(findScaling)
            wfdb_argument{end+1}='-a';
        end
    case 'prediction'
        wfdb_argument{end+1}='-P';
    case 'smooth'
        wfdb_argument{end+1}='-S';
        y3=' ';
    otherwise
        error(['Unkown estimation mode: ' estimationMode])
end

javaWfdbExec.setArguments(wfdb_argument);

if(config.inOctave)
    x=cellstr(num2str(x));
    x=java2mat(javaWfdbExec.execWithStandardInput(x));
    Nx=x.size;
    out=cell(Nx,1);
    for n=1:Nx
        out{n}=x.get(n-1);
    end
else
    out=cell(javaWfdbExec.execWithStandardInput(x).toArray);
end
M=length(out);
if(~isempty(y3))
    y3=out{end};
    out(end)=[];
    M=M-1;
    if(strcmp(estimationMode,'smooth'))
        tmp=y3;
        sep=regexp(tmp,'\s');
        y3=str2num(tmp(sep(end):end));
    end
end
if(~isempty(strfind(out{1},'Possibly')))
    warning(out{1})
    out(1)=[];
    M=M-1;
end

y1=zeros(M,1)+NaN;
y2=zeros(M,1)+NaN;
for m=1:M
    str=out{m};
    sep=regexp(str,'\s');
    y1(m)=str2num(str(1:sep));
    y2(m)=str2num(str(sep(1):end));
end

for n=1:nargout
    eval(['varargout{n}=y' num2str(n) ';'])
end





