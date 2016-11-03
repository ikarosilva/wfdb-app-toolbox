# Notes 



## Documentation ##


https://www.mathworks.com/help/matlab/ref/mex.html
https://www.mathworks.com/help/matlab/matlab_external/standalone-example.html
Call in matlab: help mex



## General ##

Compile in terminal with: mex program.c
or compile in matlab: mex program.c 

Output executable: program.mex
Gateway function (the equivalent of main) MUST be:

```
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
}
```

Location of matrix.h and mex.h: 
/usr/local/MATLAB/R2016b/extern/include/matrix.h + mex.h 

The mex executable should automatically include the path so no need to -I. 

matrix.h contains the prototypes for the many checking functions like:
bool mxIsChar(const mxArray *pm); // Determine whether input is mxChar array


## My old compiling:


mex LDFLAGS='-L/home/cx1111/PhysionetProjects/mextests -lhelperfunctions -Wl,-rpath=/home/cx1111/PhysionetProjects/mextests' arrayProduct2.c

mex LDFLAGS='-L/usr/local/lib -lwfdb -Wl,--enable-new-dtags,-rpath,/usr/local/lib' wfdbread.c









# New

## Linux 


// I think the LDFLAGS thing should be for within matlab, not terminal.
mex LDFLAGS='-L/usr/local/lib -lwfdb -Wl,--enable-new-dtags,-rpath,/usr/local/lib' mexrdsamp.c





// Try this for terminal:

mex `wfdb-config --libs` mexrdsamp.c // Doesn't work. Doesn't know what -Wl is. 


mex -L/usr/local/lib -lwfdb mexrdsamp.c // This works 








