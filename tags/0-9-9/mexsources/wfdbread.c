/*=================================================================
 *
 * WFDBREAD.C 
 *
 *
 * This is a MEX-file for MATLAB.  
 * Copyrleft 2015 Ikaro Silva
 *
 *=================================================================*/

/* To compile:
 *
 *  1) Make  sure MATLAB starts with the proper
 *  Environment settings (PATH, LD_LIBRARY_PATH) and that
 *  wfdb.h and libwfdb.so are in the current directory.
 *
 * 2) From the command prompt run:
 * 
 *    mex wfdbread.c libwfdb.so
 *
 *
 */

#include <math.h>
#include "mex.h"
#include "wfdb.h"
#include "mexRdsamp.c"


void mexFunction( int nlhs, mxArray *plhs[], 
		int nrhs, const mxArray*prhs[] )
{ 
	/* Check for proper number of arguments */
	if (nrhs < 1) {
		mexErrMsgIdAndTxt( "MATLAB:wfdbread:invalidNumInputs",
				"WFDB Record Name required.");
	}

	/* Get record name */
	char *rec_name;
	size_t reclen;
	reclen = mxGetN(prhs[0])*sizeof(mxChar)+1;
	rec_name = malloc(sizeof(long));

	int status;
	status = mxGetString(prhs[0], rec_name, (mwSize)reclen);

	/*Call WFDB Code */
	int argc=5;
	char *argv[argc];
	argv[0]="mexRdsamp.c";
	argv[1] = "-r";
	argv[2] = rec_name;
	argv[3] = "-t";
	argv[4] = " ";

	rdsamp(argc,argv);

    /* Create a 0-by-0 mxArray; memory
     * will be allocated dynamically by rdsamp */
    plhs[0] = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);

    /* Set output variable to the allocated memory space */
    mxSetPr(plhs[0],dynamicData);
    mxSetM(plhs[0],nSamples);
    mxSetN(plhs[0],nsig);
    /* free local memory */
	free(rec_name);
	return;

}
