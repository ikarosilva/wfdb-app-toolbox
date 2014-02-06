
This folder is provided for those advanced users who want to use the WFDB APP Toolbox with their 
custom version of the WFDB native binaries. Several reason why a user would want to do that include:

*Users who are in an unsupported architecture (such as 32 bit systems etc)

*Users who want to test on an older version of the WFDB library

*Users who wan to test on a new version of the WFDB library that has not yet been deployed with this toolbox


Users should compile the WFDB binary and put them in their respective folder:

bin
lib
lib64

An example is provided in this folder that was build on Linux Debian Wheezy. You can use the Makefile in this directory
as a starting point for compiling all the necessary targets on your architecture or version of WFDB. Once the code has been 
compiled. Please make sure that you set the flag:

'use_custom_nativlib=1'   
   
In the /mcode/wfdbloadlib.m function to true in order to load these native applications.
   
NOTE: Use of these custom configurations are unsupported by the PhysioNet team.  