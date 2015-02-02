function [varargout]=mat2wfdb(varargin)
%
% [xbit]=mat2wfdb(X,fname,Fs,bit_res,adu,info,gain,sg_name,baseline,isint)
%
% Convert data readable in matlab into WFDB Physionet format.
%
% Input Paramater are:
%
% X       -(required)  NxM matrix of M signals with N samples each. The
%                      signals can be of type double.The signals are assumed to be
%                      in physical units already and will be converted to
%                      ADU.
% fname   -(required)  String where the the header (*.hea) and data (*.dat)
%          files will be saved (one single name for both, with no sufix).
% Fs      -(Optional)  1x1 sampling frequency in Hz (all signals must have
%          been sampled at the same frquency). Default is 1 Hz.
% bit_res -(Optional)  1xM (or Mx1):scalar determining the bit depth of the conversion for
%                      each signal.
%                      1x1 : If all the signals should have the same bit depth
%          Options are: 8,  16, and 32 ( all are signed types). 16 is the default.
% adu     -(Optional)  Cell array of strings describing the physical units (default is 'V').
%          If only one string is entered all signals will have the same physical units.
%          If multiple physical units, the total units entered has to equal M (number of
%          channels). Units are delimited by '/'. See examples below.
% info    -(Optional)  String that will be added to the comment section of the header file.
% gain    -(Optional) Scalar, if provided, no automatic scaling will be applied before the
%          quantitzation of the signal. If a gain is passed,  in will be the same one set
%          on the header file. The signal will be scaled by this gain prior to the quantization
%          process. Use this options if you want to have a standard gain and quantization
%          process for all signals in a dataset (the function will not attempt to quantitized
%          individual waveforms based on their individual range and baseline).
%baseline   -(Optional) Offset (ADC zero) Mx1 array of integers that represents the amplitude (sample
%           value) that would be observed if the analog signal present at the ADC inputs had a
%           level that fell exactly in the middle of the input range of the ADC.
% sg_name -(Optional) Cell array of strings describing signal names.
%
% isint  -(Optional) Logical value (default=0). Use this option if you know
%           the signal is already quantitized, and you want to remove round-off
%           error by setting the original values to integers prior to fixed
%           point conversion.
%
% Ouput Parameters are:
%
% xbit    -(Optional)  NxM the quantitized signals that written to file (possible
%          rescaled if no gain was provided at input). Useful for comparing
%          and estimating quatitization error with the input double signal X
%          (see examples below).
%
%
%  NOTE: The signals can have different amplitudes, they will all be scaled to
%  a reference gain, with the scaling factor saved in the *.hea file.
%
%Written by Ikaro Silva 2010
%Modified by Louis Mayaud 2011
% Version 1.0
%
% Since 0.0.1
% See also wrsamp, wfdbdesc
%
%%%%%%%%%%  Example 1 %%%%%%%%%%%%
%
% display('***This example will write a  Ex1.dat and Ex1.hea file to your current directory!')
% s=input('Hit "ctrl + c" to quit or "Enter" to continue!');
%
% %Generate 3 different signals and convert them to signed 16 bit in WFDB format
% clear all;clc;close all
% N=1024;
% Fs=48000;
% tm=[0:1/Fs:(N-1)/Fs]';
% adu='V/mV/V';
% info='Example 1';
%
%
% %First signal a ramp with 2^16 unique levels and is set to (+-) 2^15 (Volts)
% %Thus the header file should have one quant step equal to (2^15-(-2^15))/(2^16) V.
% sig1=double(int16(linspace(-2^15,2^15,N)'));
%
% %Second signal is a sine wave with 2^8 unique levels and set to (+-) 1 (mV)
% %Thus the header file should one quant step equal a (1--1)/(2^16)  adu step
% sig2=double(int8(sin(2*pi*tm*1000).*(2^7)))./(2^7);
%
% %Third signal is a random binary signal set to to (+-) 1 (V) with DC (to be discarded)
% %Thus the header file should have one quant step equal a 1/(2^16) adu step.
% sig3=(rand(N,1) > 0.97)*2 -1 + 2^16;
%
% %Concatenate all signals and convert to WFDB format with default 16 bits (empty brackets)
% sig=[sig1 sig2 sig3];
% mat2wfdb(sig,'Ex1',Fs,[],adu,info)
%
% % %NOTE: If you have WFDB installed you can check the conversion by
% % %uncomenting and this section and running (notice that all signals are scaled
% % %to unit amplitude during conversion, with the header files keeping the gain info):
%
% % !rdsamp -r Ex1 > foo
% % x=dlmread('foo');
% % subplot(211)
% % plot(sig)
% % subplot(212)
% % plot(x(:,1),x(:,2));hold on;plot(x(:,1),x(:,3),'k');plot(x(:,1),x(:,4),'r')
%
%%%%%%%% End of Example 1%%%%%%%%%

%endOfHelp
machine_format='l';
skip=0;

%Set default parameters
params={'x','fname','Fs','bit_res','adu','info','gain','sg_name','baseline','isint'};
Fs=1;
adu=[];
info=[];
isint=0;
%Use cell array for baseline and gain in case of empty conditions
baseline=[];
gain=[];
sg_name=[];
x=[];
fname=[];
%Convert signal from double to appropiate type
bit_res = 16 ;
bit_res_suport=[8 16 32];

for i=1:nargin
    if(~isempty(varargin{i}))
        eval([params{i} '= varargin{i};'])
    end
end
[N,M]=size(x);
adu=regexp(adu,'/','split');

if(isempty(gain))
    gain=cell(M,1); %Generate empty cells as default
elseif(length(gain)==1)
    gain=repmat(gain,[M 1]);
    gain=num2cell(gain);
else
    gain=gain;
end
if(isempty(sg_name))
    sg_name=repmat({''},[M 1]);
end
if(isempty(adu))
    adu=repmat({'V'},[M 1]);
end
if ~isempty(setdiff(bit_res,bit_res_suport))
    error(['Bit res should be any of: ' num2str(bit_res_suport)]);
end
if(isempty(baseline))
    baseline=cell(M,1); %Generate empty cells as default
elseif(length(baseline)==1)
    baseline=repmat(baseline,[M 1]);
    baseline=num2cell(baseline);
end

%Header string
head_str=cell(M+1,1);
head_str(1)={[fname ' ' num2str(M) ' ' num2str(Fs) ' ' num2str(N)]};

%Loop through all signals, digitizing them and generating lines in header
%file
eval(['y=int' num2str(bit_res) '(zeros(N,M));'])  %allocate space
for m=1:M
    nameArray = regexp(fname,'/','split');
    if ~isempty(nameArray)
        fname = nameArray{end};
    end
    
    [tmp_bit1,bit_gain,baseline_tmp,ck_sum]=quant(x(:,m), ...
        bit_res,gain{m},baseline{m},isint);
    
    y(:,m)=tmp_bit1;
    head_str(m+1)={[fname '.dat ' num2str(bit_res) ' ' num2str(bit_gain) '(' ...
        num2str(baseline_tmp) ')/' adu{m} ' ' '0 0 0 ' num2str(ck_sum) ' 0 ' sg_name{m}]};
end
if(length(y)<1)
    error(['Converted data is empty. Exiting without saving file...'])
end

%Write *.dat file
fid = fopen([fname '.dat'],'wb',machine_format);
if(~fid)
    error(['Could not create data file for writing: ' fname])
end

count=fwrite(fid,y',['int' num2str(bit_res)],skip,machine_format);

if(~count)
    fclose(fid);
    error(['Could not data write to file: ' fname])  
end

fprintf(['Generated *.dat file: ' fname '\n'])
fclose(fid);

%Write *.hea file
fid = fopen([fname '.hea'],'w');
for m=1:M+1
    if(~fid)
        error(['Could not create header file for writing: ' fname])
    end
    fprintf(fid,'%s\n',head_str{m});
end

if(~isempty(info))
    count=fprintf(fid,'#%s',info);
end

if(nargout==1)
    varargout(1)={y};
end
fprintf(['Generated *.hea file: ' fname '\n'])
fclose(fid);

%%%End of Main %%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%Helper function
function [y,adc_gain,baseline,check_sum]=quant(x,bit_res,gain,baseline,isint)
%shift so that the signal midrange is at 0

min_x=min(x(~isnan(x)));
nan_ind=isnan(x);
rg=max(x(~isnan(x)))-min_x;
if(isempty(baseline))
    baseline=min_x + (rg/2);
end
x=x-baseline;

if(isempty(gain))
    %ADC gain (ADC units per physical unit). This value is a floating-point number
    %that specifies the difference in sample values that would be observed if a step
    %of one physical unit occurred in the original analog signal. For ECGs, the gain
    %is usually roughly equal to the R-wave amplitude in a lead that is roughly parallel
    %to the mean cardiac electrical axis. If the gain is zero or missing, this indicates
    %that the signal amplitude is uncalibrated; in such cases, a value of 200 (DEFGAIN,
    %defined in <wfdb/wfdb.h>) ADC units per physical unit may be assumed.
    
    %Dynamic range of encoding / Dynamic Range of Data --but leave 1 quant level for NaN
    adc_gain=(2^(bit_res-1)-1)/(rg/2);
    y=x.*adc_gain;
    
    if(isint)
        %Use this option if you know the signal is quantitized, and you
        %want to remove round-off error by setting the original values to
        %integers prior to fixed point conversion
        df_db=min(diff(sort(unique(y))));
        y=y/df_db;
        adc_gain=adc_gain/df_db;
    end
    
else
    %if gain is alreay passed don't do anything to the signal
    %the gain will be used in the header file only
    %Convert the signal to integers before encoding in order minimize round off
    %error
    adc_gain=gain;
    y=x;
end


%convert to appropiate bit type
eval(['y=int' num2str(bit_res) '(y);'])

%Shift WFDB NaN int value to a lower value so that they will not be read as NaN's by WFDB
WFDBNAN=-32768;
iswfdbnan=find(y==WFDBNAN); %-12^15 are NaNs in WFDB
if(~isempty(iswfdbnan))
    y(iswfdbnan)=WFDBNAN-1;
end

%Set NaNs to WFDBNAN
y(nan_ind)=WFDBNAN;

%Calculate the 16-bit signed checksum of all samples in the signal
check_sum=sum(y);
M=check_sum/(2^15);
if(M<0)
    check_sum=mod(check_sum,-2^15);
    if(~check_sum && abs(M)<1)
        check_sum=-2^15;
    elseif (mod(ceil(M),2))
        check_sum=2^15 + check_sum;
    end
else
    check_sum=mod(check_sum,2^15);
    if(mod(floor(M),2))
        check_sum=-2^15+check_sum;
    end
end

%Calculate baseline (ADC units):
%The baseline is an integer that specifies the sample
%value corresponding to 0 physical units.
baseline=baseline.*adc_gain;
baseline=-round(baseline);




function y=get_names(str,deli)

y={};
old=1;
ind=regexp(str,deli);
ind(end+1)=length(str)+1;
for i=1:length(ind)
    y(end+1)={str(old:ind(i)-1)};
    old=ind(i)+1;
end



