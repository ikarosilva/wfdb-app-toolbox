function wfdbdemo()
% WFDB App Toolbox Demo
%
% Written by Ikaro Silva, 2013
%
%

%Read sample ECG signal from MIT-BIH Arrhythmia Database
N=10000;
[tm,ecg]=rdsamp('mitdb/100',1,N);

%Read annotations (human labels) of QRS complexes performend on the signals
%by cardiologists.
[ann,type,subtype,chan,num]=rdann('mitdb/100','atr',1,N);

%Plot 2D version of signal and labels
figure
plot(tm(1:N),ecg(1:N));hold on;grid on
plot(tm(ann(ann<N)+1),ecg(ann(ann<N)+1),'ro');


%Stack the ECG signals based on the labeled QRSs
%and plot 3D version of signal and labels
[RR,tms]=ann2rr('mitdb/100','atr',N);
delay=round(0.1/tm(2));
M=length(RR);
offset=0.3;
stack=zeros(M,max(RR))+NaN;
qrs=zeros(M,2)+NaN;
for m=1:M
   stack(m,1:RR(m)+1)=ecg(tms(m)-delay:tms(m)+RR(m)-delay);
   qrs(m,:)=[delay+1 ecg(tms(m))];
end
figure
[X,Y] = meshgrid(1:max(RR)+1,1:M);
surf(Y,X,stack);hold on;grid on
shading interp
plot3(1:M,qrs(:,1),qrs(:,2)+offset,'go-','MarkerFaceColor','g')
view(120, 30);
axis off