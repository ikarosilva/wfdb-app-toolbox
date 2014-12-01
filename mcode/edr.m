function y=edr(varargin)
%
% y = edr(data_type,signal,r_peaks,fs,pqoff, jpoff, gain_ecg, channel, show)
%
% ECG-derived Respiratory (EDR) signal computation from given
% single-lead ECG signal based on the signed area under the QRS complex.
%
% Required Parameters:
%
% data_type
%       A 1x1 integer specifying the file data_type
%       0 --> if Matlab file
%       1 --> if record in MIT format
%
% signal
%       A Nx1 integer array containing the ECG signal in mV (if data_type=0)
%       OR a char string containing record name (if data_type=1)
%
% fs
%       A 1x1 integer specifying the sampling frequency in hz (for Matlab variables only)
%
% r_peaks
%
%       A Mx1 integer array containing locations of r peaks on signal in s
%       OR a char string containing the extension of the annotation file
%       with r peaks in samples (e.g. "qrs") (if data_type=1)
%
% optional parameters:
%
% gain_ecg
%       A 1x1 integer specifying dig_max/phy_max (default=1)
%
% channel
%       A 1x1 integer>1 (default=1) indicating ECG channel (if data_type=1)
%
% pqoff
%       A 1x1 integer>0 specifying average distance between PQ junction and
%       R peak, in samples
%
% jpoff
%       A 1x1 integer>0 specifying average distance between R peak and
%       J point, in samples
%
% show
%       A 1x1 boolean if true, generates a plot of the estimated
%       respiration signal (default = 0).
%
%
% output:
%
% y
%       A Mx2 integer matrix containing time in seconds and edr
%
% This code was written by Sara Mariani at the Wyss Institute at Harvard
% based on the open-source PhysioNet code edr.c
% (http://www.physionet.org/physiotools/edr/)
% by George Moody
%
% Author: Sara Mariani, 2014
% Last Modified: November 17, 2014
%
% please report bugs/questions at sara.mariani@wyss.harvard.edu
%
% Example - Extract EDR signal from ECG in PhysioNet's Remote server:
% signal='fantasia/f1o02';
% r_peaks='ecg';
% data_type=1;
% channel=2;
% show=1;
% y=edr(data_type,signal,r_peaks,[],[],[],channel,show);
% wfdb2mat('f1o02')
% [~,signal,Fs,~]=rdmat('f1o02m');
% resp=signal(:,1);
% resp=resp-mean(resp);
% resp=resp*200;
% sec=length(resp)/Fs;
% xax=[.25:.25:sec];
% r=interp1(y(:,1), y(:,2), xax, 'spline');
% figure
% plot(xax,r)
% hold on
% plot([1:length(resp)]/Fs,resp,'r')
% legend('edr','respiratory signal')
% xlabel('time (s)')
%
% see also: ecgpuwave, gqrs

%endOfHelp



%Set default pararameter values
inputs={'data_type','signal','r_peaks','fs','pqoff','jpoff', 'gain_ecg', 'channel' ,'show'};
show=0;
Ninputs=length(inputs);
if nargin>Ninputs
    error('Too many input arguments')
end
if nargin<3
    error('Not enough input arguments')
end

for n=1:nargin
    eval([inputs{n} '=varargin{n};'])
end
for n=nargin+1:Ninputs
    eval([inputs{n} '=[];'])
end

% check format and obtain all the features I need
if data_type==0 %matlab
    
    if  isempty(gain_ecg)
        gain_ecg=1;
    end
    ECGm=signal*gain_ecg;
    if isempty(r_peaks)
        error('R peaks locations not provided')
    else
        tqrs=round(r_peaks*fs); %samples where I have the R peak
    end
    
elseif data_type==1 %wfdb record
    if isempty(channel)
        channel=1;
    end
    % read the signal
    wfdb2mat(signal);
    pp=strfind(signal,'/');
    if ~isempty(pp)
        signal2=signal(pp(end)+1:length(signal));
    else signal2=signal;
    end
    [~,sig,fs]=rdmat([signal2 'm']);
    ECGm=sig(:,channel);
    if numel(fs)>1
        fs=fs(channel);
    end
    % read the header
    signal
    siginfo=wfdbdesc(signal);
    siginfo=siginfo(:,channel);
    gainstring=siginfo.Gain;
    sp=strfind(gainstring,' ');
    try
        gain_ecg=str2num(gainstring(1:sp-1));
    catch
        gain_ecg=1;
    end
    if strfind(gainstring(end-1),'m')
        gain_ecg=gain_ecg*1000;
    end
    
    ECGm=ECGm*gain_ecg;
    % read r_peaks if annotation file
    if ischar(r_peaks)
        [ann,ty]=rdann(signal,r_peaks);
        tqrs=ann(ty=='N');
        r_peaks=tqrs/fs;
    else
        tqrs=round(r_peaks*fs); %samples where I have the R peak
    end
    
else error('format data_type must be 0 or 1')
end

% check if signal is upside-down
if mean(ECGm(tqrs))<mean(ECGm)
    ECGm=-ECGm;
end

% EDR COMPUTATION
% 1) filter the signal with a moving window of lpflen=25 ms
lpflen=0.025;
lp=round(lpflen*fs);
w=ones(lp+1,1)./(lp+1);
sample=filter(w,1,ECGm);
% correct for the delay of lp/2
sample(1:round(lp/2))=[];
% correct for the initialization
for i=1:round(lp/2)
    sample(i)=mean(ECGm(1:i+round(lp/2)));
end
% 2) find the baseline: moving window again of bflen=1 s
bflen=1;
b=round(bflen*fs);
w2=ones(b+1,1)./(b+1);
baseline=filter(w2,1,sample);
% correct for the delay of b/2
baseline(1:round(b/2))=[];
% correct for the initialization
for i=1:round(b/2)
    baseline(i)=mean(sample(1:i+round(b/2)));
end

% 3) find average boundaries of QRS interval
if isempty(jpoff)||isempty(pqoff)
    [pqoff, jpoff]=boundaries(sample, baseline, tqrs, fs);
end

% now estimate signed area under QRS complex
sb=sample(1:length(baseline))-baseline;
snar=zeros(size(tqrs));

for i=2:length(tqrs)-1
    win=sb(tqrs(i)-pqoff:tqrs(i)+jpoff);
    snar(i)=sum(win);
end
if tqrs(end)+jpoff>length(sb)
    win=sb(tqrs(end)-pqoff:end);
else
    win=sb(tqrs(end)-pqoff:tqrs(end)+jpoff);
end
snar(end)=sum(win);

% now start from signed area and estimate edr
xm=0;
xd=0;
xdmax=0;
xc=0;
x=snar;
r=zeros(size(x));
for i=25:length(x)
    d=x(i)-xm;
    if xc<500
        xc=xc+1;
        dn=d/xc;
    else
        dn=d/xc;
        if dn>xdmax
            dn=xdmax;
        elseif dn<-xdmax
            dn=-xdmax;
        end
    end
    xm=xm+dn;
    xd=xd+abs(dn)-xd/(xc);
    if xd<1
        xd=1;
    end
    xdmax=3*xd/(xc);
    r(i)=d/xd;
end
y=r*50;
while (max(y)>127 || min(y)<-128)
    y(y<-128)=y(y<-128)+255;
    y(y>127)=y(y>127)-255;
end

if(show)
    scrsz = get(0,'ScreenSize');
    figure('Position',...
        [0.05*scrsz(3) 0.05*scrsz(4) 0.8*scrsz(3) 0.89*scrsz(4)],...
        'Color',[1 1 1]);
    ax(1)=subplot(211);
    plot([1:length(sample)]/fs,sample)
    hold on
    plot([1:length(baseline)]/fs,baseline,'g')
    plot((tqrs-pqoff)/fs,mean(ECGm)*ones(size(tqrs)),'*m')
    plot((tqrs+jpoff)/fs,mean(ECGm)*ones(size(tqrs)),'*c')
    legend('filtered ecg','baseline','window start','window end')
    set(gca,'fontsize',18)
    xlabel('time (s)','fontsize',18)
    ylim([mean(ECGm)-5*std(ECGm) mean(ECGm)+5*std(ECGm)])
    ax(2)=subplot(212);
    plot(r_peaks,y,'r')
    title('edr','fontsize',18)
    set(gca,'fontsize',18)
    xlabel('time (s)','fontsize',18)
    linkaxes(ax,'x')
end
 y=[r_peaks y];
end


%%%% Helper function %%%%%%


function[pqoff, jpoff]=boundaries(sample, baseline, tqrs, fs)
% estimate the noise level
sb=sample(1:length(baseline))-baseline;
nlest=mean(abs(sb));
display(['The estimated noise level is ' num2str(nlest) ' microvolts']);
dlthresh=2*nlest;
dlthmax=1200;
dlthmin=140;
if dlthresh>dlthmax, dlthresh=dlthmax;
elseif dlthresh<dlthmin, dlthresh=dlthmin;
end

% determine if samples are baseline
vwindow=100;
twin1=0.033;
twin2=0.067;
% time of the 51st QRS
last=tqrs(51);
sample2=sample(1:last);
bline=zeros(size(sample2));
% a sample is baseline if I have twin1 or twin2 consecutive samples
% that vary in amplitude by no more than dlthresh
for i=1:length(sample2)-twin1*fs
    vmax=sample(i);
    vmin=sample(i);
    if abs(baseline(i)-vmax)<vwindow, twindow=twin1;
    else twindow=twin2;
    end
    ww=sample(i:i+round(twindow*fs));
    if max(ww)-min(ww)<dlthresh
        bline(i)=1;
    end
end
% for first 50 beats, look for PQ junction and J point
tlim2=0.060;
tlim3=0.100;
PQ=zeros(50,1);
J=zeros(50,1);

for j=1:50
    % search to the left
    try
        w=bline(round(tqrs(j)-tlim2*fs):tqrs(j)-1);
    catch
        display(j)
        w=bline(1:tqrs(j)-1);
    end
    f=find(w);
    if numel(f)>0
        PQ(j)=length(w)-max(f)+1;
    else
        PQ(j)=length(w);
    end
    % search to the right
    w=bline(tqrs(j)+1:round(tqrs(j)+tlim3*fs));
    f=find(w);
    if numel(f)>0
        J(j)=min(f);
    else
        J(j)=length(w);
    end
end

% incremental average
pqoff=PQ(1);
for i=1:length(PQ)
    if PQ(i)<pqoff
        pqoff=pqoff-1;
    elseif PQ(i)>pqoff
        pqoff=pqoff+1;
    end
end
jpoff=J(1);
for i=1:length(J)
    if J(i)<jpoff
        jpoff=jpoff-1;
    elseif J(i)>jpoff
        jpoff=jpoff+1;
    end
end
end
