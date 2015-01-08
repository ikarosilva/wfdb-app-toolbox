function varargout = wfdbRecordViewer(varargin)
% WFDBRECORDVIEWER MATLAB code for wfdbRecordViewer.fig
%      WFDBRECORDVIEWER, by itself, creates a new WFDBRECORDVIEWER or raises the existing
%      singleton*.
%
%      H = WFDBRECORDVIEWER returns the handle to a new WFDBRECORDVIEWER or the handle to
%      the existing singleton*.
%
%      WFDBRECORDVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WFDBRECORDVIEWER.M with the given input arguments.
%
%      WFDBRECORDVIEWER('Property','Value',...) creates a new WFDBRECORDVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before wfdbRecordViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to wfdbRecordViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help wfdbRecordViewer

% Last Modified by GUIDE v2.5 17-Dec-2014 13:15:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @wfdbRecordViewer_OpeningFcn, ...
    'gui_OutputFcn',  @wfdbRecordViewer_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before wfdbRecordViewer is made visible.
function wfdbRecordViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to wfdbRecordViewer (see VARARGIN)

global current_record records tm tm_step

% Choose default command line output for wfdbRecordViewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
[filename,directoryname] = uigetfile('*.hea','Select signal header file:');
cd(directoryname)
tmp=dir('*.hea');

N=length(tmp);
records=cell(N,1);
current_record=1;
for n=1:N
    fname=tmp(n).name;
    records(n)={fname(1:end-4)};
    if(strcmp(fname,filename))
        current_record=n;
    end
end
set(handles.RecorListMenu,'String',records)
set(handles.RecorListMenu,'Value',current_record)
loadRecord(records{current_record})
loadAnnotationList(records{current_record},handles);
set(handles.slider1,'Max',tm(end))
set(handles.slider1,'Min',tm(1))
set(handles.slider1,'SliderStep',[1 1]);
sliderStep=get(handles.slider1,'SliderStep');
tm_step=(tm(end)-tm(1)).*sliderStep(1);

wfdbplot(handles)
analysisplot(handles)



function varargout = wfdbRecordViewer_OutputFcn(~,~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;

function PreviousButton_Callback(hObject, eventdata, handles)
global current_record records

current_record=current_record - 1;
set(handles.RecorListMenu,'Value',current_record);
Refresh(hObject, eventdata, handles)


function NextButton_Callback(hObject, eventdata, handles)
global current_record records
current_record=current_record + 1;
set(handles.RecorListMenu,'Value',current_record);
Refresh(hObject, eventdata, handles)


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
    ['Close ' get(handles.figure1,'Name') '...'],...
    'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in RecorListMenu.
function RecorListMenu_Callback(hObject, eventdata, handles)

global current_record records
current_record=get(handles.RecorListMenu,'Value');
Refresh(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function RecorListMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
wfdbplot(handles)


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function loadRecord(fname)
global tm signal info tm_step
h = waitbar(0,'Loading Data. Please wait...');
try
    [tm,signal]=rdmat(fname);
catch
    [tm,signal]=rdsamp(fname);
end
info=wfdbdesc(fname);

close(h)

function loadAnn1(fname,annName)
global ann1
h = waitbar(0,'Loading Annotations. Please wait...');
if(strcmp(fname,'none'))
    ann1=[];
else
    [ann1,type,subtype,chan,num,comments]=rdann(fname,annName);
end
close(h)

function loadAnn2(fname,annName)
global ann2
h = waitbar(0,'Loading Annotations. Please wait...');
if(strcmp(fname,'none'))
    ann1=[];
else
    [ann2,type,subtype,chan,num,comments]=rdann(fname,annName);
end
close(h)

function loadAnnotationList(fname,handles)
global ann1 ann2 annDiff
ann1=[];
ann2=[];
annDiff=[];
tmp=dir([fname '*']);
annotations={'none'};
exclude={'dat','hea','edf','mat'};
for i=1:length(tmp)
    name=tmp(i).name;
    st=strfind(name,'.');
    if(~isempty(st))
        tmp_ann=name(st+1:end);
        enter=1;
        for k=1:length(exclude)
            if(strcmp(tmp_ann,exclude{k}))
                enter=0;
            end
        end
        if(enter)
            annotations(end+1)={tmp_ann};
        end
    end
end

set(handles.Ann1Menu,'String',annotations)
set(handles.Ann2Menu,'String',annotations)


function wfdbplot(handles)
global tm signal info tm_step ann1 ann2 annDiff ann1RR
axes(handles.axes1);
cla;

%Normalize each signal and plot them with an offset
[N,CH]=size(signal);
offset=0.5;

%Get time info
center=get(handles.slider1,'Value');
maxSlide=get(handles.slider1,'Max');
minSlide=get(handles.slider1,'Min');
if(tm_step == ( tm(end)-tm(1) ))
    tm_start=tm(1);
    tm_end=tm(end);
elseif(center==maxSlide)
    tm_end=tm(end);
    tm_start=tm_end - tm_step;
elseif(center==minSlide)
    tm_start=tm(1);
    tm_end=tm_start + tm_step;
else
    tm_start=center - tm_step/2;
    tm_end=center + tm_step/2;
end
[~,ind_start]=min(abs(tm-tm_start));
[~,ind_end]=min(abs(tm-tm_end));

DC=min(signal(ind_start:ind_end,:),[],1);
sig=signal - repmat(DC,[N 1]);
SCALE=max(sig(ind_start:ind_end,:),[],1);
SCALE(SCALE==0)=1;
sig=offset.*sig./repmat(SCALE,[N 1]);
OFFSET=offset.*[1:CH];
sig=sig + repmat(OFFSET,[N 1]);
msize=5;

for ch=1:CH;
    plot(tm(ind_start:ind_end),sig(ind_start:ind_end,ch))
    hold on ; grid on
    if(~isempty(ann1))
        tmp_ann1=ann1((ann1>ind_start) & (ann1<ind_end));
        if(~isempty(tmp_ann1))
            if(length(tmp_ann1)<30)
                msize=8;
            else
                msize=5;
            end
            plot(tm(tmp_ann1),OFFSET(ch),'go','MarkerSize',msize,'MarkerFaceColor','g')
        end
    end
    if(~isempty(ann2))
        tmp_ann2=ann2((ann2>ind_start) & (ann2<ind_end));
        if(~isempty(tmp_ann2))
            if(length(tmp_ann2)<30)
                msize=8;
            else
                msize=5;
            end
            plot(tm(tmp_ann2),OFFSET(ch),'r*','MarkerSize',msize,'MarkerFaceColor','r')
        end
    end
    if(~isempty(info(ch).Description))
        text(tm(ind_start),ch*offset+0.8*offset,info(ch).Description,'FontWeight','bold','FontSize',12)
    end
    
end
set(gca,'YTick',[])
set(gca,'YTickLabel',[])
set(gca,'FontSize',10)
set(gca,'FontWeight','bold')
xlabel('Time (seconds)')

%Plot annotations in analysis window
if(~isempty(annDiff) & (get(handles.AnnotationMenu,'Value')==2))
    axes(handles.AnalysisAxes);
    df=annDiff((ann1>ind_start) & (ann1<ind_end));
    plot(tm(tmp_ann1),df,'k*-')
    text(tm(tmp_ann1(1)),max(df),'Ann Diff','FontWeight','bold','FontSize',12)
    grid on
    ylabel('Diff (seconds)')
    xlim([tm(ind_start) tm(ind_end)])
end

%Plot RR series in analysis window
if(~isempty(ann1RR) & (get(handles.AnnotationMenu,'Value')==3))
    axes(handles.AnalysisAxes);
    ind=(ann1(1:end-1)>ind_start) & (ann1(1:end-1)<ind_end);
    tm_ind=ann1(ind);
    df=ann1RR(ind);
    plot(tm(tm_ind),df,'k*-')
    try
        text(tm(tm_ind(1)),max(df),'RR Series','FontWeight','bold','FontSize',12)
    catch
        deb=1;
    end
    grid on
    ylabel('Interval (seconds)')
    if(~isnan(ind_start) && ~isnan(ind_end) && ~(ind_start==ind_end))
        xlim([tm(ind_start) tm(ind_end)])
    end
    
end



function analysisplot(handles)




% --- Executes on selection change in TimeScaleSelection.
function TimeScaleSelection_Callback(hObject, eventdata, handles)
global tm_step tm

TM_SC=[tm(end)-tm(1) 120 60 30 15 10 5 1];
index = get(handles.TimeScaleSelection, 'Value');
%Normalize step to time range
stp=TM_SC(index)/TM_SC(1);
set(handles.slider1,'SliderStep',[stp stp*10]);
tm_step=TM_SC(1).*stp(1);

axes(handles.axes1);
cla;
wfdbplot(handles)

% --- Executes during object creation, after setting all properties.
function TimeScaleSelection_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in AmplitudeScale.
function AmplitudeScale_Callback(hObject, eventdata, handles)
wfdbplot(handles)


% --- Executes during object creation, after setting all properties.
function AmplitudeScale_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Ann1Menu.
function Ann1Menu_Callback(hObject, eventdata, handles)
global ann1 records current_record

ind = get(handles.Ann1Menu, 'Value');
annStr=get(handles.Ann1Menu, 'String');
loadAnn1(records{current_record},annStr{ind})
wfdbplot(handles)


% --- Executes during object creation, after setting all properties.
function Ann1Menu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Ann2Menu.
function Ann2Menu_Callback(hObject, eventdata, handles)
global ann2 records current_record

ind = get(handles.Ann2Menu, 'Value');
annStr=get(handles.Ann2Menu, 'String');
loadAnn2(records{current_record},annStr{ind})
wfdbplot(handles)


% --- Executes during object creation, after setting all properties.
function Ann2Menu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function AnnotationMenu_Callback(hObject, eventdata, handles)

global ann1 ann1RR info tm
tips=0;
Fs=double(info(1).SamplingFrequency);
annStr=get(handles.AnnotationMenu,'String');
index=get(handles.AnnotationMenu,'Value');
switch(annStr{index})
    case 'Plot Annotation Differences'
        h = waitbar(0,'Comparing Annotations. Please wait...');
        annDiff=[];
        %Compare annotation with ann1menu being the reference
        N=length(ann1);
        if(~isempty(ann2))
            [A1,A2]=meshgrid(ann1,ann2);
            annDiff=min(abs(A1-A2))./Fs;
        end
        close(h)
        wfdbplot(handles)
        
    case 'Plot RR Series Ann1'
        h = waitbar(0,'Generating RR Series. Please wait...');
        %Compare annotation with ann1menu being the reference
        ann1RR=diff(ann1)./double(info(1).SamplingFrequency);
        close(h)
        wfdbplot(handles)
        
    case 'Add annotations to Ann1'
        %Get closest sample using ginput
        if(tips)
            helpdlg('Left click to add multiple annotations. Hit Enter when done.','Adding Annotations');
        end
        axes(handles.axes1);
        [x,~]= ginput;
        
        %Convert to samples ann to ann1
        x=round(x*Fs);
        ann1=sort([ann1;x]);
        %Refresh annotation plot
        wfdbplot(handles)
        
    case 'Delete annotations from Ann1'
        
        %Get closest sample using ginput
        if(tips)
            helpdlg('Left click on annotations to remove multiple. Hit Enter when done.','Removing Annotations');
        end
        axes(handles.axes1);
        [x,~]= ginput;
        rmN=length(x);
        rm_ind=zeros(rmN,1);
        for n=1:rmN
            [~,tmp_ind]=min(abs(x(n)-tm(ann1)));
            rm_ind(n)=tmp_ind;
        end
        if~(isempty(rm_ind))
            ann1(rm_ind)=[];
        end
        %Refresh annotation plot
        wfdbplot(handles)
        
    case 'Delete annotations in a range from Ann1'
        
        %Get closest sample using ginput
        if(tips)
            helpdlg('Left click on start and end regions. Hit Enter when done.','Removing Annotations');
        end
        axes(handles.axes1);
        [x,~]= ginput;
        [~,start_ind]=min(abs(x(end-1)-tm(ann1)));
        [~,end_ind]=min(abs(x(end)-tm(ann1)));
        ann1(start_ind:end_ind)=[];
        %Refresh annotation plot
        wfdbplot(handles)
        
    case 'Edit annotations in Ann1'
        %Modify closest sample using ginput
        if(tips)
            helpdlg('Left click on waveform will shift closest annotation to the clicked point. Hit Enter when done.','Adding Annotations');
        end
        axes(handles.axes1);
        [x,~]= ginput;
        editN=length(x);
        edit_ind=zeros(editN,1);
        for n=1:editN
            [~,tmp_ind]=min(abs(x(n)-tm(ann1)));
            edit_ind(n)=tmp_ind;
        end
        if~(isempty(edit_ind))
            ann1(edit_ind)=round(x*Fs);
        end
        %Refresh annotation plot
        wfdbplot(handles)
        
    case 'Add annotations in a range from Ann2 to Ann2'
        global ann2
        if(tips)
            helpdlg('Left click on waveform to select start and end of region to add from Ann2 to Ann1. Hit Enter when done.','Adding Annotations');
        end
        axes(handles.axes1);
        [x,~]= ginput;
        [~,start_ind]=min(abs(x(1)-tm(ann2)));
        [~,end_ind]=min(abs(x(2)-tm(ann2)));
        ann1=sort([ann1;ann2(start_ind:end_ind)]);
        %Refresh annotation plot
        wfdbplot(handles)
        
    case 'Save modified annotations of Ann1'
        global records current_record
        defaultAnn=get(handles.Ann1Menu,'String');
        defaultInd=get(handles.Ann1Menu,'Value');
        defName={[defaultAnn{defaultInd} '_x']};
        newAnn=inputdlg('Enter new annotation name:','Save Annotation',1,defName);
        h=waitbar(0,['Saving annotation file: ' records{current_record} '.' newAnn{1}]);
        wrann(records{current_record},newAnn{1},ann1);
        close(h)
        
end


function AnnotationMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Refresh(hObject, eventdata, handles)
global records current_record

loadRecord(records{current_record})
loadAnnotationList(records{current_record},handles)
Ann1Menu_Callback(hObject, eventdata, handles)
Ann2Menu_Callback(hObject, eventdata, handles)
AnalysisMenu_Callback(hObject, eventdata, handles)


% --- Executes on button press in TagButton.
function TagButton_Callback(hObject, eventdata, handles)

global records current_record
h = waitbar(0,['Generating tag file: ' records{current_record} '.tag']);
wrann(records{current_record},'tag',1);
close(h)
