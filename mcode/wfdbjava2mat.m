function matrix = wfdbjava2mat(array)
%
% [matrix]=wfdbjava2mat(array)
%
% This function takes a one-dimensional or two-dimensional array of
% Java values, and converts it to a matrix or vector. This conversion
% is automatic and implicit in Matlab and is sometimes automatic in
% Octave (depending on the data type and dimensionality) but in other
% cases an explicit conversion is needed.

if(isnumeric(array))
    matrix=array;
else
    if(exist('java_matrix_autoconversion','builtin'))
        java_matrix_autoconversion(1,'local');
    else
        java_convert_matrix(1,'local');
    end

    if(exist('__java2mat__','builtin'))
        matrix=builtin('__java2mat__',array);
    else
        matrix=java2mat(array);
    end

    if(~isnumeric(matrix))
        matrix=javaObject('org.octave.Matrix',array);
        if(exist('__java2mat__','builtin'))
            matrix=builtin('__java2mat__',matrix);
        else
            matrix=java2mat(matrix);
        end
    end
end

end
