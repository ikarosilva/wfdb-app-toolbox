/*=================================================================
 *
 * WFDBREAD.C 
 *
 *
 * This is a MEX-file for MATLAB.  
 * Copyrleft 2015 Ikaro Silva
 *
 *=================================================================*/

/* To compile run in MATLAB:
 *
 * 
 *    mex -v wfdbread.c
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
	double *yp;
	double *t,*y;
	size_t m,n;

	/* Check for proper number of arguments */
	if (nrhs < 1) {
		mexErrMsgIdAndTxt( "MATLAB:yprime:invalidNumInputs",
				"WFDB Record Name required.");
	}

	/* Get record name */
	char *rec_name;
	unsigned long *nSamples;
	long *nsig;
	long* input_data; /*To be allocated by mexRdsamp.c*/

	size_t reclen;
	reclen = mxGetN(prhs[0])*sizeof(mxChar)+1;
	rec_name = malloc(sizeof(long));
	nsig = malloc(sizeof(long));
	if (nsig == NULL || rec_name ==NULL) {
		mexPrintf("Unable to allocate enough memory to read record!");
		return;
	}

	int status;
	status = mxGetString(prhs[0], rec_name, (mwSize)reclen);

	/*Run WFDB Code */
	int argc=5;
	char *argv[argc];
	argv[0]="mexRdsamp.c";
	argv[1] = "-r";
	argv[2] = rec_name;
	argv[3] = "-t";
	argv[4] = "s5";

	main(argc,argv,input_data,nSamples,nsig);

	/* Deallocate requested memory */
	mxFree(rec_name);
	free(nSamples);
	free(nsig);
	free(input_data);

	return;

}






