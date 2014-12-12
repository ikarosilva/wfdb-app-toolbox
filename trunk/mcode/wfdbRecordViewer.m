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

% Last Modified by GUIDE v2.5 12-Dec-2014 16:40:29

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
directoryname = uigetdir('', 'Select Database Directory');
cd(directoryname)
tmp=dir('*.hea');

N=length(tmp);
records=cell(N,1);
for n=1:N
    records(n)={tmp(n).name(1:end-4)};
end
current_record=1;
set(handles.popupmenu1,'String',records)
loadRecord(records{current_record})
loadAnnotationList(records{current_record},handles);
set(handles.slider1,'Max',tm(end))
set(handles.slider1,'Min',tm(1))
set(handles.slider1,'SliderStep',[1 1]);
sliderStep=get(handles.slider1,'SliderStep');
tm_step=(tm(end)-tm(1)).*sliderStep(1);
if strcmp(get(hObject,'Visible'),'off')
    wfdbplot(handles)
end




% UIWAIT makes wfdbRecordViewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = wfdbRecordViewer_OutputFcn(~,~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
cla;
global current_record records

current_record=current_record - 1;
set(handles.popupmenu1,'Value',current_record);
loadRecord(records{current_record})
loadAnnotationList(records{current_record},handles)
wfdbplot(handles)
Ann1_CreateFcn(hObject, eventdata, handles)
Ann2_CreateFcn(hObject, eventdata, handles)
CompareAnn_Callback(hObject, eventdata, handles)

% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
cla;
global current_record records 

current_record=current_record + 1;
set(handles.popupmenu1,'Value',current_record);
loadRecord(records{current_record})
loadAnnotationList(records{current_record},handles)
wfdbplot(handles)
Ann1_CreateFcn(hObject, eventdata, handles)
Ann2_CreateFcn(hObject, eventdata, handles)
CompareAnn_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
    ['Close ' get(handles.figure1,'Name') '...'],...
    'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
axes(handles.axes1);
cla;
wfdbplot(handles)


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function loadRecord(fname)
global tm signal info
try
    [tm,signal]=rdmat(fname);
catch
    [tm,signal]=rdsamp(fname);
end
info=wfdbdesc(fname);

function loadAnn1(fname,annName)
global ann1
[ann1,type,subtype,chan,num,comments]=rdann(fname,annName);

function loadAnn2(fname,annName)
global ann2
[ann2,type,subtype,chan,num,comments]=rdann(fname,annName);

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

set(handles.Ann1,'String',annotations)
set(handles.Ann2,'String',annotations)


function wfdbplot(handles)

global tm signal info tm_step ann1 ann2 annDiff

%Normalize each signal and plot them with an offset
[N,CH]=size(signal);
offset=0.5;

%Get time info
center=get(handles.slider1,'Value');
if(tm_step == ( tm(end)-tm(1) ))
    tm_start=tm(1);
    tm_end=tm(end);
else
    tm_start=center - tm_step/2;
    tm_end=center + tm_step/2;
end
[~,ind_start]=min(abs(tm-tm_start));
[~,ind_end]=min(abs(tm-tm_end));

DC=min(signal(ind_start:ind_end,:));
sig=signal - repmat(DC,[N 1]);
SCALE=max(sig(ind_start:ind_end,:));
SCALE(SCALE==0)=1;
sig=offset.*sig./repmat(SCALE,[N 1]);
OFFSET=offset.*[1:CH];
sig=sig + repmat(OFFSET,[N 1]);

for ch=1:CH;
    plot(tm(ind_start:ind_end),sig(ind_start:ind_end,ch))
    hold on ; grid on
    if(~isempty(ann1))
        tmp_ann1=ann1((ann1>ind_start) & (ann1<ind_end));
        plot(tm(tmp_ann1),OFFSET(ch),'go','MarkerSize',5,'MarkerFaceColor','g')
    end
    if(~isempty(ann2))
        tmp_ann2=ann2((ann2>ind_start) & (ann2<ind_end));
        plot(tm(tmp_ann2),OFFSET(ch),'r*','MarkerSize',5,'MarkerFaceColor','r')
    end
    text(tm(ind_start),ch*offset+offset/2,info(ch).Description,'FontWeight','bold','FontSize',12)
    
end
if(~isempty(annDiff))
    df=annDiff-min(annDiff((ann1>ind_start) & (ann1<ind_end)));
    df=offset.*df./max(df((ann1>ind_start) & (ann1<ind_end)));
    df=df((ann1>ind_start) & (ann1<ind_end));
    plot(tm(tmp_ann1),df,'k*-')
    text(tm(tmp_ann1(1)),offset/2,'Ann Diff','FontWeight','bold','FontSize',12)
    
end

set(gca,'YTick',[])
set(gca,'YTickLabel',[])
set(gca,'FontSize',10)
set(gca,'FontWeight','bold')
xlabel('Time (s)')


% --- Executes on selection change in TimeScaleSelection.
function TimeScaleSelection_Callback(hObject, eventdata, handles)
% hObject    handle to TimeScaleSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TimeScaleSelection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TimeScaleSelection
global tm_step tm

TM_SC=[tm(end)-tm(1) 60*2 30*2 10*2 5*2 1*2];
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
% hObject    handle to TimeScaleSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in AmplitudeScale.
function AmplitudeScale_Callback(hObject, eventdata, handles)
% hObject    handle to AmplitudeScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AmplitudeScale contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AmplitudeScale
axes(handles.axes1);
cla;
wfdbplot(handles)


% --- Executes during object creation, after setting all properties.
function AmplitudeScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AmplitudeScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Ann1.
function Ann1_Callback(hObject, eventdata, handles)
% hObject    handle to Ann1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Ann1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Ann1
global ann1 records current_record

ind = get(handles.Ann1, 'Value');
annStr=get(handles.Ann1, 'String');
if(ind ~=1)
    loadAnn1(records{current_record},annStr{ind})
    axes(handles.axes1);
    cla;
    wfdbplot(handles)
end


% --- Executes during object creation, after setting all properties.
function Ann1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Ann1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Ann2.
function Ann2_Callback(hObject, eventdata, handles)
% hObject    handle to Ann2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Ann2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Ann2
global ann2 records current_record

ind = get(handles.Ann2, 'Value');
annStr=get(handles.Ann2, 'String');
if(ind ~=1)
    loadAnn2(records{current_record},annStr{ind})
    axes(handles.axes1);
    cla;
    wfdbplot(handles)
end

% --- Executes during object creation, after setting all properties.
function Ann2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Ann2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in CompareAnn.
function CompareAnn_Callback(hObject, eventdata, handles)
% hObject    handle to CompareAnn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CompareAnn
global tm  signals ann1 ann2 annDiff info

value=get(hObject,'Value');
annDiff=[];
if(value==1)
    %Compare annotation with ann1 being the reference
    N=length(ann1);
    if(~isempty(ann2))
        [A1,A2]=meshgrid(ann1,ann2);
        annDiff=min(abs(A1-A2)).*double(info(1).SamplingFrequency);
    end
end
wfdbplot(handles)
