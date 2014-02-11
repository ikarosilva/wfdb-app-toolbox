function [out]=woody(x,varargin)
%
% [out]=woody(x,tol,max_it,est_mthd,xcorr_mthd)
%
% Weighted average using Woody average for a signal
% with jitter. Parameters:
%
% x             Signal measurements. Each COLUMN represents
%               and independent measure of the signal (or channel).
% tol           Tolerance paremeter to stop average (default is 0.1)
% max_it        Maximum number of iterations done on the average (default is 100).
% est_mthd      Estimation method to use. Options are:
%               'woody'     : classical approach (default)
%               'thornton'  : implements the Thornton approach that is also useful for different noise sources.
% xcorr_mthd    Determines what estimation method to use for the estimating the correlaation function using the
%               XCORR function. Options are:
%               'biased'   - scales the raw cross-correlation by 1/M.
%               'unbiased' - scales the raw correlation by 1/(M-abs(lags)). (Default)
% out           Final averaged waveform (time aligned).
%
%
%
% Written by Ikaro Silva 
%
% Since 0.9.5
%
% %%%Example 1 %%%%
% t=[0:1/1000:1];
% N=1001;
% x=sin(2*pi*t)+sin(4*pi*t)+sin(8*pi*t);
% y=exp(0.01*[-1*[500:-1:1] 0 -1*[1:500]]);
% s=x.*y;
% sig1=0;
% sig2=0.1;
% M=100;
% S=zeros(N,M);
% center=501;
% TAU=round((rand(1,M)-0.5)*160);
% for i=1:M,
%     tau=TAU(i);
%     
%     if(tau<0)
%         S(:,i)=[s(-1*tau:end)'; zeros(-1*(tau+1),1)];
%     else
%         S(:,i)=[zeros(tau,1);s(1:N-tau)'; ];
%     end
%     if(i<50)
%        S(:,i)=S(:,i) + randn(N,1).*sig1;
%     else
%         S(:,i)=S(:,i) + randn(N,1).*sig2;
%     end
% end
% 
% [wood]=woody(S,[],[],'woody','biased');
% [thor]=woody(S,[],[],'thornton','biased');
% figure;
% subplot(211)
% plot(s,'b','LineWidth',2);grid on;hold on;plot(S,'r');plot(s,'b','LineWidth',2)
% legend('Signal','Measurements')
% subplot(212)
% plot(s);hold on;plot(mean(S,2),'r');plot(wood,'g');plot(thor,'k')
% legend('Signal','Normal Ave','Woody Ave','Thornton Ave');grid on

%endOfHelp
%Default parameter values
tol= 0.1;
max_it=100;
est_mthd='woody';
xcorr_mthd='unbiased';
thornton_sub=3;         %number of subaverages to use in the thornton procedure


if(nargin>1)
    if(~isempty(varargin{1}))
        tol=varargin{1};
    end
    if(nargin>2)
        if(~isempty(varargin{2}))
            max_it=varargin{2};
        end
        if(nargin>3)
            if(~isempty(varargin{3}))
                est_mthd=varargin{3};
            end
            if(nargin>4)
                if(~isempty(varargin{4}))
                    xcorr_mthd=varargin{4};
                end
            end
        end
    end
end


%Call repective averaging technique
switch est_mthd
    
    case 'woody'
        out=woody_core(x,tol,max_it,xcorr_mthd);
        
    case 'thornton'
        %Implement procedure from Thornton 2008
        [N,M]=size(x);
        K=floor(M/thornton_sub);
        
        %Call woody several times implementing the subaverages
        for k=1:K
            
            sub=thornton_sub*k;
            ind=round(linspace(1,M,sub+1));
            
            if((length(ind)-2) > (M/2))
                %Number of subaverages is equal to or just less than
                %half the number of trials, move to the final stage
                %and exit loop
                [out,est_lags]=woody_core(x,tol,max_it,xcorr_mthd);
                break
            end
                      
            %Get woody average from the subaverages
            %procedure converges when there is no lag changes
            y=gen_subave(x,ind); %Generate sub averages
            y_old=y;
            err=1;
            while(err)
                [trash,est_lags]=woody_core(y,tol,max_it,xcorr_mthd);
                x=shift_data(x,est_lags,ind,N,M);
                y=gen_subave(x,ind); %Re-generate sub averages
                err=sum(abs(y(:)-y_old(:)));
                y_old=y;
            end
            
        end
        
        
    otherwise
        error(['Invalid option for est_mthd parameter: ' xcorr_mthd ' valid options are: woody, weighted, and thornton'])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%End of Maing Function%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





%%%%%Helper Functions%%%%%%%%%%%%



function    x=shift_data(x,est_lags,ind,N,M)

%Shifts individual trials within each subaverage
K=length(est_lags);
for k=1:K
    lag=est_lags(k);
    if(lag)
        if(k~=K)
            sel_ind=[ind(k):ind(k+1)-1];
        else
            sel_ind=[ind(k):M];
        end
        pad=length(sel_ind);
        if(lag>0)
            x(:,sel_ind)=[zeros(lag-1,pad); x(lag:end,sel_ind)];
            %x(:,sel_ind)=[randn(lag-1,pad).*mean(std(x(:,sel_ind))).*0.001; x(lag:end,sel_ind)];
        elseif(lag<0)
            x(:,sel_ind)=[x(1:N+lag,sel_ind); zeros(lag*-1,pad)];
            %x(:,sel_ind)=[x(1:N+lag,sel_ind); randn(lag*-1,pad).*mean(std(x(:,sel_ind))).*0.001];
        end
    end
end

function [out,varargout]=woody_core(x,tol,max_it,xcorr_mthd)
[N,M]=size(x);
mx=mean(x,2);
p=zeros(N,1);
conv=1;
run=0;
sig_x=diag(sqrt(x'*x));
X=xcorr(mx);
ref=length(X)/2;
if(mod(ref,2))
    ref=ceil(ref);
else
    ref=floor(ref);
end

if(nargout>1)
    %In this case we output the lag of the trials as well
    lag_data=zeros(1,M);
end

while(conv*(run<max_it))
    
    z=zeros(N,1);
    w=ones(N,1);
    for i=1:M,
        
        y=x(:,i);
        xy=xcorr(mx,y,xcorr_mthd);
        [val,ind]=max(xy);
        if(ind>ref)
            lag=ref-ind-1;
        else
            lag=ref-ind;
        end
        if(lag>0)
            num=w(lag:end)-1;
            z(1:N-lag+1)=( z(1:N-lag+1).*num + y(lag:end))./w(lag:end);
            w(lag:end)=w(lag:end)+1;
        elseif(lag<0)
            num=w(lag*(-1)+1:end)-1;
            z(lag*(-1)+1:end)=( z(lag*(-1)+1:end).*num + y(1:N+lag) )./w(lag*(-1)+1:end);
            w(lag*(-1)+1:end)=w(lag*(-1)+1:end)+1;
        else
            z=z.*(w-1)./w + y./w;
            w=w+1;
        end
        if(exist('lag_data','var'))
            lag_data(i)=lag;
        end
        
    end
    
    
    old_mx=mx;
    mx=z;
    p_old=p;
    p=mx'*x./(sqrt(mx'*mx).*sig_x');
    p=sum(p)./M;
    err=abs(p-p_old);
    if(err<tol)
        conv=0;
    end
    run=run+1;
    
    
end

out=mx;

if(exist('lag_data','var'))
    varargout(1)={lag_data};
end







function [y]=gen_subave(x,ind)

[N,M]=size(x);
T=length(ind)-1;
y=zeros(N,T);

%Generate Subaverages
for i=1:T-1
    y(:,i)=mean(x(:,ind(i):ind(i+1)-1),2);
end

y(:,end)=mean(x(:,ind(T):end),2);



