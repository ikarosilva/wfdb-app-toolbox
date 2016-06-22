function [varargout]=mat2wfdb(varargin)
%
% [xbit]=mat2wfdb(X,fname,Fs,bit_res,adu,info,gain,sg_name,baseline,isdigital, isquant)
%
% Convert data from a matlab array into Physionet WFDB format file.
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
% adu     -(Optional) Describes the physical units (default is 'mV').
%          Three input formats:
%            - String delimited by forward slashes (e.g. 'V/mV/mmHg'), with
%            M-1 slash characters
%            - Single string (e.g. 'V'), in which case all signals will 
%            have the same physical units.
%            - Cell array of strings, where the total units entered has to equal M 
%            (number of channels).
% info    -(Optional)  String that will be added to the comment section of the header file.
%           For multi-lined comments, use a cell array of strings. Each
%           cell will be output on a new line. Note that comments in the
%           header file are automatically prefixed with a pound symbol (#)
% gain    -(Optional) Scalar or Mx1 array of floats indicating the difference in sample values 
%           that would be observed if a step of one physical unit occurred in the original 
%           analog signal. If the 'isdigital' field is 1, this field is mandatory. Otherwise,
%           this field is ignored if present. 
% baseline -(Optional) Mx1 array of integers that specifies the sample value for each channel
%           corresponding to 0 physical units. Not to be confused with 'ADC zero' which 
%           is currently always taken and written as 0 in this function. If
%           the 'isdigital' field is 1, this field is mandatory. Otherwise,
%           this field is ignored if present. 
% sg_name -(Optional) Cell array of strings describing signal names.
%
% isquant   -(Optional) Logical value (default=0). Use this option if the
%           input signal is already quantitized, and you want to remove round-off
%           error by setting the original values to integers prior to fixed
%           point conversion. This field is only used for input physical
%           signals. If 'isdigital' is set to 1, this field is ignored.
%
% isdigital -(Optional) Logical value (default=0). Specifies whether the input signal is 
%            digital or physical (default). If it is digital, the signal values will be 
%            directly written to the file without scaling. If the signal is physical, 
%            the optimal gain and baseline will be calculated and used to digitize the signal
%            to write the WFDB file. This flag also decides the allowed
%            input combinations of the 'gain' and 'baseline' fields.
%            Digital signals must have both, and physical signals must have
%            neither (as the ideal values will be automatically calculated). 
%
% Ouput Parameter:
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
%Modified by Louis Mayaud 2011, Alistair Johson 2016
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
% %Thus the header file should one quant step equal a (1--1)/(2^8)  adu step
% sig2=double(int8(sin(2*pi*tm*1000).*(2^7)))./(2^7);
%
% %Third signal is a random binary signal set to to (+-) 1 (V) with DC (to be discarded)
% %Thus the header file should have one quant step equal a 1/(2^15) adu step.
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
machine_format='l'; % all wfdb formats are little endian except fmt 61 which this function does not support. Do NOT change this.
skip=0;

% Set default parameters
params={'x','fname','Fs','bit_res','adu','info','gain','sg_name','baseline','isquant', 'isdigital'};
Fs=1;
adu=[];
info=[];
isquant=0;
isdigital=0;
%Use cell array for baseline and gain in case of empty conditions
baseline=[];
gain=[];
sg_name=[];
x=[];
fname=[];
%Used to convert signal from double to appropiate type
bit_res = 16 ;
bit_res_suport=[8 16 32];

for i=1:nargin
    if(~isempty(varargin{i}))
        eval([params{i} '= varargin{i};'])
    end
end

% Check valid gain and baseline combinations depending on whether the input is digital or physical.
if isdigital % digital input signal
    if (isempty(gain) || isempty(baseline))
        error('Input digital signals are directly written to files without scaling. Must also input gain and baseline for correct interpretation of written file.');   
    end
else % physical input signal
    if ( ~isempty(gain) || ~isempty(baseline)) % User inputs gain or baseline to map the physical to digital values.
        % Sorry, we cannot trust that they did it correctly... 
        warning('Input gain and baseline fields ignored for physical input signal. This function automatically calculates and applies the ideal values');
    end
end
    
switch bit_res % Write formats. 
    case 8
        fmt='80';
    case 16
        fmt='16';
    case 32
        fmt='32';
end

[N,M]=size(x);

if isempty(adu) % default unit: 'mV'
    adu=repmat({'mV'},[M 1]);
elseif iscell(adu) 
    % adu directly input as a cell array of strings
elseif ischar(adu)
    if ~isempty(strfind(adu,'/'))
        adu=regexp(adu,'/','split');
    else
        adu = repmat({adu},[M,1]);
    end
end

% ensure we have the right number of units
if numel(adu) ~= M
    error('adu:wrongNumberOfElements','adu cell array has incorrect number of elements');
end

if(isempty(gain))
    gain=cell(M,1); %Generate empty cells as default
elseif(length(gain)==1)
    gain=repmat(gain,[M 1]);
end
% ensure gain is a cell array
if isnumeric(gain)
    gain=num2cell(gain);
end

if(isempty(sg_name))
    sg_name=repmat({''},[M 1]);
end
if ~isempty(setdiff(bit_res,bit_res_suport))
    error(['Bit res should be one of: ' num2str(bit_res_suport)]);
end
if(isempty(baseline))
    baseline=cell(M,1); %Generate empty cells as default
elseif(length(baseline)==1)
    baseline=repmat(baseline,[M 1]);
end
% ensure baseline is a cell array
if isnumeric(baseline)
    baseline=num2cell(baseline);
end

%Head record specification line
head_str=cell(M+1,1);
head_str(1)={[fname ' ' num2str(M) ' ' num2str(Fs) ' ' num2str(N)]};

switch bit_res % Allocate space for digital signals
    case 8
        y=uint8(zeros(N,M));
    case 16
        y=int16(zeros(N,M));
    case 32
        y=int32(zeros(N,M));
end

%Loop through all signals, digitizing them and generating lines in header file
for m=1:M
    nameArray = regexp(fname,'/','split');
    if ~isempty(nameArray)
        fname = nameArray{end};
    end
    
    [tmp_bit1,bit_gain,baseline_tmp,ck_sum]=quant(x(:,m), ...
        bit_res, gain{m}, baseline{m}, isquant, isdigital);
    
    y(:,m)=tmp_bit1;
    
    % Header file signal specification lines
    head_str(m+1)={[fname '.dat ' fmt ' ' num2str(bit_gain) '(' ...
        num2str(baseline_tmp) ')/' adu{m} ' ' '0 0 ' num2str(tmp_bit1(1)) ' ' num2str(ck_sum) ' 0 ' sg_name{m}]};
end
if(length(y)<1)
    error(['Converted data is empty. Exiting without saving file...'])
end

%Write *.dat file
fid = fopen([fname '.dat'],'wb',machine_format);
if(~fid)
    error(['Could not create data file for writing: ' fname])
end


if (bit_res==8)
    count=fwrite(fid, y','uint8',skip,machine_format);
else
    count=fwrite(fid, y',['int' num2str(bit_res)],skip,machine_format);
end


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
    if ischar(info)
        fprintf(fid,'#%s',info);
    elseif iscell(info)
        for m=1:numel(info)
            fprintf(fid,'#%s\n',info{m});
        end
    end
end

if(nargout==1)
    varargout(1)={y};
end
fprintf(['Generated *.hea file: ' fname '\n'])
fclose(fid);

end

%%%End of Main %%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Helper function
function [y,adc_gain,baseline,check_sum]=quant(x, bit_res, gain, baseline, isquant, isdigital)
%shift so that the signal midrange is at 0

min_x=min(x(~isnan(x)));
max_x=max(x(~isnan(x)));
nan_ind=isnan(x);
rg=max_x-min_x;

if(isdigital) 
    % Digital input signal. Do not scale or shift the signal. The gain/baseline will only 
    % be used to write the header file to interpret the output wfdb record.
    if ((min_x < -2^(bit_res-1)) || (max_x > (2^(bit_res-1)-1 )))
        error('Digital input signal exceeds allowed range of specified format: [-2^(bit_res-1) < x < 2^(bit_res-1)-1]');
    end
    adc_gain=gain;
    y=x;
    
else
    % Physical input signal - calculate the gain and baseline to minimize
    % the detail loss during ADC conversion: y = gain*x + baseline
    % Ignore any input gain or baseline
    
    % Calculate the adc_gain
    if rg==0 % Zero-range signal. Manually set adc_gain or gain will be infinite.
        adc_gain=1; % If the signal is all zeros, store all digital values as the min digital
                    % value and gain as 1. 
        
        % Need to test both cases where signal is all 0's and all non-zero.
        
    else % Normal case 
        % adc_gain = (range of encoding / range of Data) -- remember 1 quant level is for storing NaN
        adc_gain=((2^bit_res)-1)/rg;
    end
    
    %Calculate baseline and map the signal to digital. 
    if(isquant)
        % The input signal was already quantitized, remove round-off error by setting the 
        % original values to integers prior to fixed point conversion
        
        df_db=min(diff(sort(unique(x)))); % An estimate of the smallest increment in the input signal
        adc_gain=1/df_db; % 1 digital unit corresponds to the smallest physical increment. 
        baseline=round(-(2^(bit_res-1))+1-min_x*adc_gain);  
        y=x*adc_gain+baseline; 
        
    else % Input signal was not quantized. 
        baseline=round(-(2^(bit_res-1))+1-min_x*adc_gain);  
        y=x*adc_gain+baseline; 
    end
    
end % signal is in digital range and adc_gain and baseline have been calculated. 

%Convert signals to appropriate integer type. 
%Shift any WFDB NaN int values to a higher value so that they will not be read as NaN's by WFDB
switch bit_res % WFDB will interpret the smallest value as nan. 
    case 8
        WFDBNAN=-128;
        y=int8(y); 
    case 16
        WFDBNAN=-32768;
        y=int16(y);
    case 32
        WFDBNAN=-2147483648;
        y=int32(y);
end
iswfdbnan=find(y==WFDBNAN); 
if(~isempty(iswfdbnan))
    y(iswfdbnan)=WFDBNAN+1;
end

%Set original NaNs to WFDBNAN
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

% Note that checksum must be calculated on actual digital samples for format 80,
% not the shifted ones. Therefore we only convert to real format now. 
if bit_res==8
    y=uint8(int16(y)+128); % Convert into unsigned for writing byte offset format. 
end

% Signal is ready to be written to dat file. 

end


function y=get_names(str,deli)

y={};
old=1;
ind=regexp(str,deli);
ind(end+1)=length(str)+1;
for i=1:length(ind)
    y(end+1)={str(old:ind(i)-1)};
    old=ind(i)+1;
end

end


