function y = edr(type,signal,r_peaks, pqoff, jpoff, fs, gain, channel)
% ECG-derived Respiratory (EDR) signal computation
% from given single-lead ECG signal
% based on the signed area under the QRS complex. 
%
% input: type --> 0 (matlab file)
%                   containing ECG in uV
%                 1 (MIT format record)
%        signal --> Matlab single-column vector (if type=0)
%                   OR string containing record name (if type=1)
%        for matlab files also specify
%        fs --> sampling frequency in hz
%        gain (default=1) --> dig_max/phy_max
%
% optional inputs: channel --> (for type=1), integer>1
%                  indicating ECG channel
%                  r_peaks --> row vector containing location of r peaks on signal in s
%                  pqoff, jpoff --> average distance of PQ junction
%                  and J point from R peak, in samples
%
% output: y --> two-column matrix containing time in seconds and y
%         
% This code was written by Sara Mariani at the Wyss Institute at Harvard
% based on the open-source PhysioNet code edr.c
% (http://www.physionet.org/physiotools/edr/)
% by George Moody
% and includes the function rpeakdetect by Gari Clifford
% and the function readheader by Salvador Olmos
%
%
% Author: Sara Mariani
%
% please report bugs/questions at sara.mariani@wyss.harvard.edu

if nargin>8
    error('Too many input arguments')
end

% check format and obtain all the features I need
if type==0 %matlab   
if nargin<6
   error('Not enough input arguments')
else
    if nargin<7 || isempty(gain)
        gain=1; 
    end 
    ECG=signal*gain;
end
elseif type==1 %wfdb record
    if isempty(channel)
        channel=1;
    end
    % read the signal
    [~,ECG,fs]=rdsamp(signal,channel);
    % read the header
    heasig=readheader([signal '.hea']);
    gain=heasig.gain(1);
    if strfind(heasig.units(1),'m')
        gain=gain*1000;
    end
    fs=heasig.freq;
    ECG=ECG*gain;
else error('format type must be 0 or 1')
end
    
% R peaks
if isempty(r_peaks)
        [~, r_peaks, ~, ~, ~, ~]  = rpeakdetect(ECG,fs);
end
tqrs=round(r_peaks*fs); %samples where I have the R peak

% check if signal is upside-down
if mean(ECG(tqrs))<mean(ECG)
    ECG=-ECG;
end

% EDR COMPUTATION
% 1) filter the signal with a moving window of lpflen=25 ms
lpflen=0.025;
lp=round(lpflen*fs);
w=ones(lp+1,1)./(lp+1);
sample=filter(w,1,ECG);
% correct for the delay of lp/2
sample(1:round(lp/2))=[];
% correct for the initialization
for i=1:round(lp/2)
    sample(i)=mean(ECG(1:i+round(lp/2)));
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
figure
ax(1)=subplot(211);
plot([1:length(sample)]/fs,sample)
hold on
plot([1:length(baseline)]/fs,baseline,'g')
plot((tqrs-pqoff)/fs,mean(ECG)*ones(size(tqrs)),'*m')
plot((tqrs+jpoff)/fs,mean(ECG)*ones(size(tqrs)),'*c')
legend('filtered ecg','baseline','window start','window end')
set(gca,'fontsize',18)
xlabel('time (s)','fontsize',18)
ylim([mean(ECG)-5*std(ECG) mean(ECG)+5*std(ECG)])
ax(2)=subplot(212);
plot(r_peaks,y,'r')
title('edr','fontsize',18)
set(gca,'fontsize',18)
xlabel('time (s)','fontsize',18)
ylabel('EDR','fontsize',18)
linkaxes(ax,'x')
y=[r_peaks' y'];
end

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

function heasig=readheader(name)
% READHEADER function reads the header of DB signal files
%	Input parameters: character string with name of header file
%	Output parameter: struct heasig with header information
%	Syntaxis:
% function heasig=readheader(name);

% Salvador Olmos
% e-mail: olmos@posta.unizar.es

% Opening header file
fid=fopen(name,'rt');
if (fid<=0)
   disp(['error in opening file ' name]);
end

pp=' /+:()x';

% First line reading
s=fgetl(fid);
% Remove blank or commented lines
while s(1)=='#'
  s=fgetl(fid);
end

[heasig.recname,s]=strtok(s,pp);
[s1 s]=strtok(s,pp);
heasig.nsig=str2num(s1);
[s1 s]=strtok(s);
if isempty(findstr(s1,'/'))
   heasig.freq=str2num(s1);
else
   [s1 s]=strtok(s,'/');
   heasig.freq=str2num(s1);
   [s1 s]=strtok(s);   
end

[s1 s]=strtok(s,pp);
heasig.nsamp=str2num(s1);

if ~isempty(deblank(s))
   [s1 s]=strtok(s,':');
   hour=str2num(s1);
   [s1 s]=strtok(s,':');
   min=str2num(s1);
   [s1 s]=strtok(s,pp);
   sec=str2num(s1);  
end

if ~isempty(deblank(s))
   [s1 s]=strtok(s,'/');
   month=str2num(s1);
   [s1 s]=strtok(s,'/');
   day=str2num(s1);
   [s1 s]=strtok(s,pp);
   year=str2num(s1);  
end
if exist('hour','var') heasig.date=datenum(year,month,day,hour,min,sec); end

% default values
for i=1:heasig.nsig
  heasig.units(i,:)='mV';
end
sig=1;

% Reading nsig lines, corresponding one for every lead
for i=1:heasig.nsig
  s=fgetl(fid);
  % Remove blank or commented lines
  while s(1)=='#'
    s=fgetl(fid);
  end

  [heasig.fname(i,:),s]=strtok(s,pp);
  [s1,s]=strtok(s,pp);
  if i==1  heasig.group(i)=0;
  else
     if strcmp(heasig.fname(i,:),heasig.fname(i-1,:)) 
        heasig.group(i)=0;
     else
        heasig.group(i)=heasig.group(i-1)+1;
     end
  end
  a=[findstr(s,'x') findstr(s,':') findstr(s,'+')];
  if isempty(a)
     heasig.fmt(i)=str2num(s1);     
  else
    [s2,s]=strtok(s);
    a=[a length(s2)+1];
    for k=1:length(a)-1
      switch (s2(a(k)))
       case '+',
     	heasig.fmt(i)=str2num(s1);
     	heasig.offset(i)=str2num(s2(a(k)+1:a(k+1)-1));  
       case ':',
     	heasig.fmt(i)=str2num(s1);
        heasig.skew(i)=str2num(s2(a(k)+1:a(k+1)-1));
       case 'x',
     	heasig.fmt(i)=str2num(s1);
     	heasig.spf(i)=str2num(s2(a(k)+1:a(k+1)-1));  
      end
    end
  end
  [s1,s]=strtok(s,pp);  
  a=[findstr(s,'(') findstr(s,'/')];
  if isempty(s1)
      heasig.gain(i)=0;
      heasig.baseline(i)=0;
  else
      if isempty(a)
        heasig.gain(i)=str2num(s1);
      else
       [s2,s]=strtok(s);
        a=[a length(s2)+1];
        for k=1:length(a)-1
  	  switch (s2(a(k)))
           case '(', 
		heasig.gain(i)=str2num(s1);
		a2=findstr(s2,')');
		heasig.baseline(i)=str2num(s2(1+a(k):a2-1));
	   case '/',
		heasig.gain(i)=str2num(s1);
                f=s2(a(k)+1:end);
		heasig.units(i,1:length(f))=f;
          end
        end
      end
      [s1,s]=strtok(s,pp);
      heasig.adcres(i)=str2num(s1);
      [s1,s]=strtok(s,pp);
      heasig.adczero(i)=str2num(s1);
      [s1,s]=strtok(s,pp);
      heasig.initval(i)=str2num(s1);
      [s1,s]=strtok(s,pp);
      heasig.cksum(i)=str2num(s1);
      [s1,s]=strtok(s,pp);
      heasig.bsize(i)=str2num(s1);
      heasig.desc(i,1:length(s))=s;  
  end  
end
fclose(fid);
end

function [hrv, R_t, R_amp, R_index, S_t, S_amp]  = rpeakdetect(data,samp_freq,thresh)

% [hrv, R_t, R_amp, R_index, S_t, S_amp]  = rpeakdetect(data, samp_freq, thresh); 
% R_t == RR points in time, R_amp == amplitude
% of R peak in bpf data & S_amp == amplitude of 
% following minmum. sampling frequency (samp_freq = 256Hz 
% by default) only needed if no time vector is 
% specified (assumed to be 1st column or row). 
% The 'triggering' threshold 'thresh' for the peaks in the 'integrated'  
% waveform is 0.2 by default.  testmode = 0 (default) indicates
% no graphics diagnostics. Otherwise, you get to scan through each segment.
%
% A batch QRS detector based upon that of Pan, Hamilton and Tompkins:
% J. Pan \& W. Tompkins - A real-time QRS detection algorithm 
% IEEE Transactions on Biomedical Engineering, vol. BME-32 NO. 3. 1985.
% P. Hamilton \& W. Tompkins. Quantitative Investigation of QRS 
% Detection  Rules Using the MIT/BIH Arrythmia Database. 
% IEEE Transactions on Biomedical Engineering, vol. BME-33, NO. 12.1986.
% 
% Similar results reported by the authors above were achieved, without
% having to tune the thresholds on the MIT DB. An online version in C
% has also been written.
%
% Written by G. Clifford gari@ieee.org and made available under the 
% GNU general public license. If you have not received a copy of this 
% license, please download a copy from http://www.gnu.org/
%
% Please distribute (and modify) freely, commenting
% where you have added modifications. 
% The author would appreciate correspondence regarding
% corrections, modifications, improvements etc.
%
% gari@ieee.org

%%%%%%%%%%% make threshold default 0.2 -> this was 0.15 on MIT data 
if nargin < 4
   testmode = 0;
end
%%%%%%%%%%% make threshold default 0.2 -> this was 0.15 on MIT data 
if nargin < 3
   thresh = 0.2;
end
%%%%%%%%%%% make sample frequency default 256 Hz 
if nargin < 2
   samp_freq = 256;
   if(testmode==1)
       fprintf('Assuming sampling frequency of %iHz\n',samp_freq);
   end
end

%%%%%%%%%%% check format of data %%%%%%%%%%
[a b] = size(data);
len=length(data);

%%%%%%%%%% if there's no time axis - make one 
if (a | b == 1);
% make time axis 
  tt = 1/samp_freq:1/samp_freq:ceil(len/samp_freq);
  t = tt(1:len);
  x = data;
end
%%%%%%%%%% check if data is in columns or rows
if (a == 2) 
  x=data(:,1);
  t=data(:,2); 
end
if (b == 2)
  t=data(:,1);
  x=data(:,2); 
end

%%%%%%%%% bandpass filter data - assume 256hz data %%%%%
 % remove mean
 x = x-mean(x);
 
 % FIR filtering stage
 bpf=x; %Initialise
if( (samp_freq==128) & (exist('filterECG128Hz')~=0) )
        bpf = filterECG128Hz(x); 
end
if( (samp_freq==256) & (exist('filterECG256Hz')~=0) )
        bpf = filterECG256Hz(x); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

%%%%%%%%% differentiate data %%%%%%%%%%%%%%%%%%%%%%%%%%%
 dff = diff(bpf);  % now it's one datum shorter than before

%%%%%%%%% square data    %%%%%%%%%%%%%%%%%%%%%%%%%%%
 sqr = dff.*dff;   %
 len = len-1; % how long is the new vector now? 

%%%%%%%%% integrate data over window 'd' %%%%%%%%%%%%%%%%%%%%%%%%%
 d=[1 1 1 1 1 1 1]; % window size - intialise
 if (samp_freq>=256) % adapt for higher sampling rates
   d = [ones(1,round(7*samp_freq/256))]; 
 end
 % integrate
 mdfint = medfilt1(filter(d,1,sqr),10);
 % remove filter delay for scanning back through ECG
 delay = ceil(length(d)/2);
 mdfint = mdfint(delay:length(mdfint));
%%%%%%%%% segment search area %%%%%%%%%%%%%%%%%%%%%%%
 %%%% first find the highest bumps in the data %%%%%% 
 max_h = max (mdfint(round(len/4):round(3*len/4)));

 %%%% then build an array of segments to look in %%%%%
 %thresh = 0.2;
 poss_reg = mdfint>(thresh*max_h);

%%%%%%%%% and find peaks %%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%% find indices into boudaries of each segment %%%
 left  = find(diff([0 poss_reg'])==1); % remember to zero pad at start
 right = find(diff([poss_reg' 0])==-1); % remember to zero pad at end
 
 %%%% loop through all possibilities  
 for(i=1:length(left))
    [maxval(i) maxloc(i)] = max( bpf(left(i):right(i)) );
    [minval(i) minloc(i)] = min( bpf(left(i):right(i)) );
    maxloc(i) = maxloc(i)-1+left(i); % add offset of present location
    minloc(i) = minloc(i)-1+left(i); % add offset of present location
 end

 R_index = maxloc;
 R_t   = t(maxloc);
 R_amp = maxval;
 S_amp = minval;   %%%% Assuming the S-wave is the lowest
                   %%%% amp in the given window
 S_t   = t(minloc);

%%%%%%%%%% check for lead inversion %%%%%%%%%%%%%%%%%%%
 % i.e. do minima precede maxima?
 if (minloc(length(minloc))<maxloc(length(minloc))) 
  R_t   = t(minloc);
  R_amp = minval;
  S_t   = t(maxloc);
  S_amp = maxval;
 end

%%%%%%%%%%%%
hrv  = diff(R_t);
resp = R_amp-S_amp; 
end