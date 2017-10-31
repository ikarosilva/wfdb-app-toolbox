function [tests,pass,perf]=test_woody(varargin)

inputs={'verbose'};
verbose=0;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end

%Test the examples 
% Note: This requires the Signal Processing toolbox
str=['t=[0:1/1000:1];N=1001;x=sin(2*pi*t)+sin(4*pi*t)+sin(8*pi*t);' ...
    'y=exp(0.01*[-1*[500:-1:1] 0 -1*[1:500]]);'...
  's=x.*y;sig1=0;sig2=0.1;M=100;S=zeros(N,M);center=501;TAU=round((rand(1,M)-0.5)*160);'...
  'for i=1:M;tau=TAU(i);if(tau<0)' ...
  'S(:,i)=[s(-1*tau:end)''; zeros(-1*(tau+1),1)];'...
  'else; S(:,i)=[zeros(tau,1);s(1:N-tau)''; ];end;'... 
  'if(i<50) S(:,i)=S(:,i) + randn(N,1).*sig1; else; S(:,i)=S(:,i) + randn(N,1).*sig2; end; end; '...
  '[wood]=woody(S,[],[],''woody'',''biased'');[thor]=woody(S,[],[],''thornton'',''biased'');'...
  'figure;subplot(211);' ...
  'plot(s,''b'',''LineWidth'',2);hold on;plot(S,''r'');plot(s,''b'',''LineWidth'',2);legend(''Signal'',''Measurements'');'...
  'subplot(212);plot(s);hold on;plot(mean(S,2),''r'');plot(wood,''g'');plot(thor,''k'');'...
  'legend(''Signal'',''Normal Ave'',''Woody Ave'',''Thornton Ave'');close all;'];
  
test_string={str};

clean_up={};
[tests,pass,perf]=test_wrapper(test_string,clean_up,verbose);
