function varargout=visgraph(varargin)
%
% [k,logP]=visgraph(x)
%
% Visibility Graph analysis of a time series as described in:
% 
% Lacasa, Lucas, et al. 
% "From time series to complex networks: The visibility graph." 
%  Proceedings of the National Academy of Sciences 105.13 (2008): 4972-4975.
%
% Required input parameter:
% x
%       Nx1 matrix (doubles) of time series to be analyzed.
%
%
%
% Written by Ikaro Silva, 20134
% Last Modified: November 24, 2014
% Version 1.0
%
% Since 0.9.8
%
%
% %Example
% %Generate Conway Series
% N=1000;
% a=ones(N,1);
% out=ones(N,1);
% for n=3:N
%     a(n)=a(a(n-1))+ a(n-a(n-1));
%     out(n)= a(n) - (n/2);
% end
% 
% %Generate Surrogate Data
% nS=5;
% S=surrogate(out,nS);
% subplot(3,1,1)
% plot(out);title('Conway Series')
% subplot(3,1,2)
% plot(S(:,1),'r');title('Amplitude Adjusted Surrogate Data')
% 
% %Calculate visibility graph for all series
% [k,logP]=visgraph(out);
% subplot(3,1,3)
% plot(k,logP);hold on;grid on
% 
% for n=1:nS
%     [k,logP]=visgraph(S(:,n));
%     subplot(3,1,3)
%     plot(k,logP,'r');
% end
%
% See also SURROGATE, DFA, MSENTROPY, CORRINT

%endOfHelp

persistent javaWfdbExec config
if(isempty(javaWfdbExec))
    [javaWfdbExec,config]=getWfdbClass('visbility');
end

%Set default pararamter values
inputs={'x'};
outputs={'k','logP'};
k=[];
logP=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

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
k=zeros(M,1)+NaN;
logP=zeros(M,1)+NaN;
if(length(out{end})==1)
    out(end)=[];
    M=M-1;
end
for m=1:M
    str=out{m};
    sep=regexp(str,'\s');
    k(m)=str2num(str(1:sep));
    logP(m)=str2num(str(sep(1):end));
end

for n=1:nargout
    eval(['varargout{n}=' outputs{n} ';'])
end





