
-------To install the WFDB Application Toolbox:-------

1) Unzip the zip file into the directory you wish to install the toolbox 


If you run into any problems and need to contact us, 
please send the entire output of this script.

2) From within MATLAB, cd into the directory and add it to your path:

cd wfdb-app-toolbox-0-0-1;cd mcode
addpath(pwd);savepath
wfdbdemo %Optional demoing of the toolbox



-------Getting help and information about the WFDB Toolbox--------
For a information about the Toolbox and the list of functions associated with it
type: 

wfdb

at the MATLAB prompt.  



-------To Uninstall the toolbox:-------

1)From MATLAB, find where the toolbox is installed:

install_dir=which('wfdb')

2) Remove the directory from the MATLAB path:
rmpath(install_dir);

3)(Optional) Remove the Toolbox files permanently from your machine:
delete(install_dir)



-------CONTACT: For help, feedback, and support please contact us at the following email: 
wfdb-matlab-support@physionet.org

*When contacting us about issues with the Toolbox, please send us the output of 
the "wfdbdemo" script.

