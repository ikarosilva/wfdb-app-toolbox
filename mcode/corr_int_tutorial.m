clear all;close all;clc


%Generate differen time series based on different process for analysis
N=1000; %Number of points for each process
model_names={'one','two','three','four','five'};

%Model One - Linear Auto Regressive model with measurement noise
model_one=zeros(N,1);
x=77;
model_one(1)=x;
for n=2:N
    x=4 + 0.95*x;
    model_one(n)= x + randn(1)*2;
end

%Model Two - Linear Auto Regressive model with measurement and state noise
model_two=zeros(N,1);
x=77;
model_two(1)=x;
for n=2:N
    x=4 + 0.95*x + randn(1)*3;
    model_two(n)= x + randn(1)*2;
end

%Model Three - Linear Auto Regressive model with measurement and state
%noise and 2 variables
model_three=zeros(N,1);
x=21;
y=0;
model_three(1)=x;
for n=2:N
    dx=y + randn(1)*3;
    dy=-0.5*y - 3*x;
    x= x + dx*0.1;
    y= y + dy*0.1;
    model_three(n)= x + randn(1)*1;
end


%Model Four - Deterministic Non-linear model of dimension ~ 3.9
model_four=zeros(N,1);
x=0.2;
model_four(1)=x;
for n=2:N
    x= 4*x*(1-x);
    model_four(n)= x;
end

%Model Five - Non-linear model of dimension ~ 3.9
model_five=zeros(N,1);
x=0.2;
y=0.2;
z=0.2;
v=0.2;
model_five(1)=x;
for n=2:N
    m=0.4 - 6/(1+ x^2 + y^2);
    xold=x;
    yold=y;
    zold=z;
    vold=v;
    x= 1 + 0.7*(xold*cos(m)-yold*sin(m)) + 0.2*zold;
    y=0.7*(xold*sin(m) + yold*cos(m));
    z=1.4 + 0.3*vold - zold^2;
    v=zold;
    model_five(n)= x + 0.3*z + randn(1)*0.05;
end



%Plot time series
figure(1)
for i=1:5
    subplot(5,1,i)
    eval(['plot(model_' model_names{i} ');legend(''model ' model_names{i} ''')'])
    title('Time Plot')
    xlabel('time')
end

%Plot cross correlation
figure(2)
for i=1:5
    subplot(5,1,i)
    eval(['x=model_' model_names{i} ';'])
    R=xcorr(x-mean(x),'coeff');
    plot(R(round(N):end))
    eval(['legend(''model ' model_names{i} ''')'])
    title('Autocorelation')
    xlabel('lag')
end

%Plot Phase Plots
figure(3)
for i=1:5
    subplot(2,3,i)
    eval(['x=model_' model_names{i} ';'])
    scatter(x(1:end-1),x(2:end))
    eval(['legend(''model ' model_names{i} ''')'])
    title('Phase Plot')
    xlabel('x(t)')
    ylabel('x(t+1)')
end


%Plot correlation dimensions
%Scaling  regions determined by visual inspection
timeLag=1;
timeStep=1;
distanceThreshold=[];
neighboorSize=[];
estimationMode='dimension';
figure(4)
DIMS=[1:10];
D=length(DIMS);
scaling_th=[5 12 6 10 8]; %Determined by visually searching for the scaling regions
for i=1:5
    eval(['x=model_' model_names{i} ';'])
    corrDim=zeros(D,1)+NaN;
    for d=1:D;
        embeddedDim=DIMS(d);
        [y1,y2]=corrint(x,embeddedDim,timeLag,timeStep,distanceThreshold,neighboorSize,estimationMode);
        corrDim(d)=y2(scaling_th(i));
        %figure(4+i);plot(ey1,y2,'o-');hold on %Plots for finding scaling region for each model
    end
    figure(4);
    subplot(5,1,i)
    plot(DIMS,corrDim,'o-')
    ylim([0 5])
    corrDim(isnan(corrDim))=[];
    df=corrDim(end)-corrDim(end-1);
    if(df<0.1)
        title(['Estimated Correlation Dim=' num2str(corrDim(end))])
    end
    eval(['legend(''model ' model_names{i} ''')'])
    xlabel('Embedded Dimension')
    ylabel('Corr Dim')
end




%Plot prediction errors for all the models
timeLag=1;
timeStep=1;
distanceThreshold=[];
neighboorSize=10;
estimationMode='smooth';
figure(5)
DIMS=[1:10];
D=length(DIMS);
for i=1:5
    eval(['x=model_' model_names{i} ';'])
    corrDim=zeros(D,1)+NaN;
    for d=1:D;
        embeddedDim=DIMS(d);
        [y1,y2,y3]=corrint(x,embeddedDim,timeLag,timeStep,distanceThreshold,neighboorSize,estimationMode);
        corrDim(d)=y3;
    end
    subplot(3,2,i)
    plot(DIMS,corrDim,'o-')
    eval(['legend(''model ' model_names{i} ''')'])
    xlabel('Embedded Dimension')
    ylabel('err/var')
    ylim([0 1.3])
end

%Plot prediction errors for all the models
timeLag=1;
timeStep=1;
distanceThreshold=[];
embeddedDim=4;
estimationMode='smooth';
figure(6)
K=[1:20 25 30 50 70 100];
D=length(K);
surrN=10;
for i=1:5
    eval(['x=model_' model_names{i} ';'])
    err=zeros(D,1)+NaN;
    surr_data=zeros(D,surrN);
    SURR=surrogate(x,surrN);
    for d=1:D;
        neighboorSize=K(d);
        [y1,y2,y3]=corrint(x,embeddedDim,timeLag,timeStep,distanceThreshold,neighboorSize,estimationMode);
        err(d)=y3;
        for s=1:surrN
            [y1,y2,y3]=corrint(SURR(:,s),embeddedDim,timeLag,timeStep,distanceThreshold,neighboorSize,estimationMode);
            surr_data(d,s)=y3;
        end
    end
    subplot(3,2,i)
    plot(K,err,'o-');hold on
    errorbar(K,mean(surr_data,2),var(surr_data,[],2)./sqrt(10),'r')
    eval(['legend(''model ' model_names{i} ''',''surrogate'')'])
    xlabel('Embedded Dimension')
    ylabel('err/var')
    
end






