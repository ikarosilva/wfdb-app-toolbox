%Script for testing compile configurations of MingW on Windows
clear all;clc
copyfile('mexopts.bat','C:\Users\ikaro\AppData\Roaming\MathWorks\MATLAB\R2014b')
mex -f mexopts.bat -v -largeArrayDims "C:\Program Files\MATLAB\R2014b\extern\examples\mex\yprime.c"
yprime(1,1:4)