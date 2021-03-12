function [varargout]=test_wrapper(varargin)
%
% Wrapper for testing basic functionality of the toolbox.
%
% Written by Ikaro Silva, 2013

%Set default pararamter values
inputs={'test_string','clean_up','verbose'};
outputs={'tests','pass','performance'};

pass=0;
clean_up={};
verbose=0;
cur_dir=pwd;
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};']);
    end
end
tests=length(test_string);
performance=zeros(tests,1)+NaN;
for n=1:tests
    try
        if(verbose)
           display(test_string{n});
        end
        tic;
        eval(test_string{n});
        performance(n)=toc;
        if(~isempty(clean_up) && ~isempty(clean_up{n}))
            try
              eval(clean_up{n});
            catch
              display('Clean up failed: ');
              warning(lasterr);
            end
        end
        pass=pass+1;
    catch
        fprintf(['\t****Failed test: %s\n'],num2str(n));

        display(['Last error: ' lasterr]);
        if(exist('lasterror'))
            err=lasterror;
            for m=1:length(err.stack)
                if(isfield(err.stack(m),'column'))
                    colstr=[', column ' num2str(err.stack(m).column)];
                else
                    colstr='';
                end
                display([' in ' err.stack(m).name ...
                         ' (' err.stack(m).file ...
                         ', line ' num2str(err.stack(m).line) ...
                         colstr ')']);
            end
        end
    end
end
cd(cur_dir);
for n=1:nargout
        eval(['varargout{n}=' outputs{n} ';']);
end