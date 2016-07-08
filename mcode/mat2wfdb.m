function [varargout]=mat2wfdb(varargin)
%
% [xbit]=mat2wfdb(X,fname,Fs,bit_res,adu,info,gain,sg_name,baseline,isquant, isdigital)
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
% gain    -(Required for digital only) Scalar or Mx1 array of floats indicating the difference in sample values 
%           that would be observed if a step of one physical unit occurred in the original 
%           analog signal. If the 'isdigital' field is 1, this field is mandatory. Otherwise,
%           this field is ignored if present. 
% baseline -(Required for digital only) Mx1 array of integers that specifies the sample value for each channel
%           corresponding to 0 physical units. Not to be confused with 'ADC zero' which 
%           is currently always taken and written as 0 in this function. If
%           the 'isdigital' field is 1, this field is mandatory. Otherwise,
%           this field is ignored if present. 
% sg_name -(Optional) Cell array of strings describing signal names.
%
% isquant   -(Optional) Logical value (default=0). Use this option if the
%           input signal is already quantitized and you want to remove round-off
%           error by mapping the original values to integers prior to fixed
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

disp(isdigital)
% Check valid gain and baseline combinations depending on whether the input is digital or physical.
if isdigital % digital input signal
    if (isempty(gain) || isempty(baseline))
        error('Input digital signals are directly written to files without scaling. Must also input gain and baseline for correct interpretation of written file.');   
    end
    if (~isempty(find(baseline>2147483647))||~isempty(find(baseline<-2147483648))) % baseline stored as int in wfdb library. 
        error('Baseline field must lie between 2^-31 and 2^31-1 for this WFDB version'); % Prevent bit overflow
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

if isempty(isquant)
    isquant = zeros(M,1);
elseif numel(isquant)==1
    isquant = repmat(isquant,[M,1]);
elseif numel(isquant)~=M
    error('isquant:wrongNumberOfElements','isquant  array has incorrect number of elements');
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
        bit_res, gain{m}, baseline{m}, isquant(m), isdigital);
    
    y(:,m)=tmp_bit1;
    
    % Header file signal specification lines
    % Should we specify precision of num2str(gain)?
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

min_x=min(x(~isnan(x)));
max_x=max(x(~isnan(x)));
nan_ind=isnan(x);
rg=max_x-min_x;

if(isdigital) 
    % Digital input signal. Do not scale or shift the signal. The gain/baseline will only 
    % be used to write the header file to interpret the output wfdb record.
    if ((min_x < -2^(bit_res-1)+1) || (max_x > (2^(bit_res-1)-1 )))
        error(['Digital input signal exceeds allowed range of specified output format: {' num2str(-2^(bit_res-1)+1) ' < x < ' num2str(2^(bit_res-1)-1) '}']);
    end
    adc_gain=gain;
    y=x;
    
else
    % Physical input signal - calculate the gain and baseline to minimize
    % the detail loss during ADC conversion: y = gain*x + baseline. Ignore any input gain or baseline
    
    % Calculate the adc_gain, baseline, and map the signal to digital
    % Make sure baseline doesn't go beyond 4 byte integer range
    
    if rg==0 % Flatline signal. Manually set adc_gain or it will be infinite.
          baseline=-(2^(bit_res-1))+1; % Set baseline to minimum value of bit res
          if x(1)==0
            adc_gain=1; % Arbitrary gain=1 for all 0 input signal. All values stored as baseline. 
          else
            adc_gain=-baseline/x(1); % Set gain as inverse to store all values as exactly 0.  
          end
          
    else % Non flatline signal: adc_gain = (range of encoding / range of Data) -- remember 1 quant level is for storing NaN
        % Constraint - baseline must be stored as a 4 byte integer for the WFDB library. 
        if ((min_x>0) && (bit_res==32)) % All values are +ve, map with baseline = -2^31+1
            adc_gain=((2^32)-2)/max_x; 
            baseline=-2147483647;
            if isquant==0 % Only display warning message if not recalculating later
                disp('Due to baseline constraints, output precision may be slightly less than 32 bits for the positive channel.');
            end
        elseif((max_x<0) && (bit_res==32)) % All values are -ve, map with baseline = 2^31-1
            adc_gain=((2^32)-2)/abs(min_x);
            baseline=2147483647;
            if isquant==0 % Only display warning message if not recalculating later
                disp('Due to baseline constraints, output precision may be slightly less than 32 bits for the negative channel.');
            end
        else % Signal has both +ve and -ve values or fmt is not 32. Use full range of bits. 
            adc_gain=((2^bit_res)-2)/rg;
            baseline=round(-(2^(bit_res-1))+1-min_x*adc_gain);
            
        end
        if(isquant)
            % The (non flatline) input signal was already quantitized. Remove round-off error 
            % by setting the original values to integers prior to fixed point conversion
            
            xvalues=sort(unique(x(~isnan(x)))); % All the values of x
            incmin=min(diff(xvalues)); % An estimate of the smallest possible increment in the input signal
            quantlevels=rg/incmin; % The estimated number of quantization levels in the input signal
            
            % We want to map 1 increment to 1 digital unit. First make sure
            % the full increment range is less than the 2^N-2 increments able to be encoded
            % by the chosen bit resolution. The incmin estimate will always
            % be equal to or larger than the true incmin, so it won't
            % wrongly trigger errors in this validation step. 
            
            if (quantlevels>2^bit_res-2)
                if bit_res==32
                    disp(['The input signal has more quantization levels than 32 bits -1. ' ...
                        'Cannot directly map all input values to integers. Up to 1 bit of roundoff error may occur. Continuing...']);
                    calcquant=0; % Skip the integer matching and keep the old baseline/gain calculated. 
                else
                    error(['The input signal has more quantization levels than the chosen bit resolution. ' ...
                        'Please choose a higher resolution or remove the isquant option to allow up to 1 bit of roundoff error']);
                end
            else
                calcquant=1;
            end
            
            % Calculate gain+offset. Baseline must be stored as a 4 byte integer for the WFDB library.
            if calcquant
                if ((min_x>0) && (bit_res==32)) % 32 bit +ve quant mapping
                    adc_gain=1/incmin;
                    baseline=round(2147483647-adc_gain*max_x); % map max_x to 2^31-1. 
                    if (baseline<-2147483647) % Check if baseline goes below -2^31-1. If so, no quant. Recalculate gain and base. 
                        adc_gain=((2^32)-2)/max_x; 
                        baseline=-2147483647;
                        disp('Due to baseline constraints, the channel will not be quantized. Output precision may be less than 32 bits for the positive channel.');
                    end
                elseif((max_x<0) && (bit_res==32)) % 32 bit -ve quant mapping
                    adc_gain=1/incmin;
                    baseline=round(-2147483647-adc_gain*min_x); % map min_x to -2^31+1. 
                    if (baseline>2147483647) % Check if baseline goes above 2^31-1. If so, no quant. Recalculate gain and base. 
                        adc_gain=((2^32)-2)/abs(min_x); 
                        baseline=2147483647;
                        disp('Due to baseline constraints, channel will not be quantized. Output precision may be less than 32 bits for the negative channel.');
                    end
                else % Signal has both +ve and -ve values or fmt is not 32. Can use full range of bits.
                    adc_gain=1/incmin; % 1 digital unit corresponds to the smallest physical increment.
                    baseline=round(-(2^(bit_res-1))+1-min_x*adc_gain); % xmin still maps to ymin. xmax will not go beyond y limit, baseline should not go beyond 32 bit limits.  
                end
            end
        end
        % Check for 8 and 16 bit format 'baseline' field overflow. VERY
        % uncommon situation. Occurs if entire signal is +ve or -ve
        % with very high magnitude.
        if (baseline>2147483647) % Signal is all negative with large magnitude.
            warning('Large offset input channel entered. Output precision may be less than specified format for the negative channel.');
            baseline=2147483647; % Baseline is max int value, min_x maps to min bitres value. 
            adc_gain=(-(2^(bit_res-1))+1-baseline)/min_x;
        elseif (baseline<-2147483647) % Signal is all positive with large magnitude.
            warning('Large offset input channel entered. Output precision may be less than specified format for the positive channel.');
            baseline=-2147483647; % Baseline is min int value, max_x maps to max bitres value.
            adc_gain=(2^(bit_res-1)-1-baseline)/max_x;
        end
    end

    y=x*adc_gain+baseline;
    
end % signal is in digital range. adc_gain and baseline have been calculated. 

% Convert signals to appropriate integer type, and shift any WFDB NaN int values to 
% a higher value so that they will not be read as NaN's by WFDB
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


