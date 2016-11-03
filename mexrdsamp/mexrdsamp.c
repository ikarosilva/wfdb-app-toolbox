/* Mex version of rdsamp.c adapted from original WFDB Software Package
   http://www.physionet.org/physiotools/wfdb/app/rdsamp.c

-------------------------------------------------------------------------------
Call: [signal] = mexrdsamp(recordName,signaList,N,N0,rawUnits,highResolution)

Reads a WFDB record and returns:
- signal - NxM matrix storing the record signal


Required Parameters:
- recordName - String specifying the name of the record in the WFDB path or
               current directory

Optional Parameters:
- signalList - A Mx1 array of integers specifying the channel indices to be
               returned (default = all)
- N - Integer specifying the sample number at which to stop reading the record
      file. 
- N0
- rawUnits
- highResolution

Written by Ikaro Silvia 2014
Modified by Chen Xie 2016
-------------------------------------------------------------------------------

*/

#include <stdio.h>
#include <malloc.h>
#include <math.h>
#include <wfdb/wfdb.h>
#include "matrix.h"
#include "mex.h"

double* dynamicData; // GLOBAL VARIABLES??? WHY????????? 
unsigned long nSamples;
long nsig;
long maxSamples = 2000000;
long reallocIncrement= 1000000;   /* allow the input buffer to grow (the increment is arbitrary) */
/* input data buffer; to be allocated and returned
 * channel samples will be interleaved
 */

/* Work function */
void rdsamp(int argc, char *argv[]){
  char* pname ="mexrdsamp1";
  char *record = NULL, *search = NULL;
  char *invalid, speriod[16], tustr[16];
  int  highres = 0, i, isiglist, nosig = 0, s,
    *sig = NULL;
  WFDB_Frequency freq;
  WFDB_Sample *datum;
  WFDB_Siginfo *info;
  WFDB_Time from = 0L, maxl = 0L, to = 0L;

  /* Reading input parameters */
  for(i = 1 ; i < argc; i++){
    if (*argv[i] == '-') switch (*(argv[i]+1)) {
      case 'f':	/* starting time */
	if (++i >= argc) {
	  mexPrintf( "%s: time must follow -f\n", pname);
	  return;
	}
	from = i;
	break;
      case 'H':	/* select high-resolution mode */
	highres = 1;
	break;
      case 'l':	/* maximum length of output follows */
	if (++i >= argc) {
	  mexPrintf("%s: max output length must follow -l\n",
		     pname);
	  return;
	}
	maxl = i;
	break;
      case 'P':	/* output in physical units */
	    ++pflag;
	    break;
      case 'r':	/* record name */
	if (++i >= argc) {
	  mexPrintf("%s: record name must follow -r\n",
		     pname);
	  return;
	}
	record = argv[i];
	break;
      case 's':	/* signal list follows */
	isiglist = i+1; /* index of first argument containing a signal # */
	while (i+1 < argc && *argv[i+1] != '-') {
	  i++;
	  nosig++;	/* number of elements in signal list */
	}
	if (nosig == 0) {
	  mexPrintf("%s: signal list must follow -s\n",
		     pname);
	  return;
	}
	break;
      case 'S':	/* search for valid sample of specified signal */
	if (++i >= argc) {
	  mexPrintf("%s: signal name or number must follow -S\n",
		    pname);
	  return;
	}
	search = argv[i];
	break;
      case 't':	/* end time */
	if (++i >= argc) {
	  mexPrintf("%s: time must follow -t\n",pname);
	  return;
	}
	to = i;
	break;
      default:
	mexPrintf( "%s: unrecognized option %s\n", pname,
		   argv[i]);
	return;
      }
    else {
      mexPrintf( "%s: unrecognized argument %s\n", pname,
		 argv[i]);
      return;
    }
  }
  if (record == NULL) {
    mexPrintf("No record name specified\n");
    return;
  }



  
  /* Read Input Files*/
  if ((nsig = isigopen(record, NULL, 0)) <= 0) return;

  if ((datum = malloc(nsig * sizeof(WFDB_Sample))) == NULL ||
      (info = malloc(nsig * sizeof(WFDB_Siginfo))) == NULL) {
    mexPrintf( "%s: insufficient memory\n", pname);
    return;
  }

  if ((nsig = isigopen(record, info, nsig)) <= 0)
    return;
  for (i = 0; i < nsig; i++)
    if (info[i].gain == 0.0) info[i].gain = WFDB_DEFGAIN;
  if (highres)
    setgvmode(WFDB_HIGHRES);
  freq = sampfreq(NULL);
  if (from > 0L && (from = strtim(argv[from])) < 0L)
    from = -from;
  if (isigsettime(from) < 0)
    return;
  if (to > 0L && (to = strtim(argv[to])) < 0L)
    to = -to;
  if (nosig) {	/* print samples only from specified signals */
    if ((sig = (int *)malloc((unsigned)nosig*sizeof(int))) == NULL) {
      mexPrintf( "%s: insufficient memory\n", pname);
      return;
    }
    for (i = 0; i < nosig; i++) {
      if ((s = findsig(argv[isiglist+i])) < 0) {
	mexPrintf( "%s: can't read signal '%s'\n", pname,
		   argv[isiglist+i]);
	return;
      }
      sig[i] = s;
    }
    nsig = nosig;
  }
  else {	/* print samples from all signals */
    if ((sig = (int *) malloc( (unsigned) nsig*sizeof(int) ) ) == NULL) {
      mexPrintf( "%s: insufficient memory\n", pname);
      return;
    }
    for (i = 0; i < nsig; i++)
      sig[i] = i;
  }

  /* Reset 'from' if a search was requested. */
  if (search &&
      ((s = findsig(search)) < 0 || (from = tnextvec(s, from)) < 0)) {
    mexPrintf( "%s: can't read signal '%s'\n", pname, search);
    return;
  }

  /* Reset 'to' if a duration limit was specified. */
  if (maxl > 0L && (maxl = strtim(argv[maxl])) < 0L)
    maxl = -maxl;
  if (maxl && (to == 0L || to > from + maxl))
    to = from + maxl;

  /* Read in the data in raw units */
  mexPrintf("creating output matrix for %u signals and %u samples\n",
	    nsig,maxSamples);

  if ( (dynamicData= mxRealloc(dynamicData,maxSamples * nsig * sizeof(double)) ) == NULL) {
    mexPrintf("Unable to allocate enough memory to read record!");
    mxFree(dynamicData);
    return;
  }

  mexPrintf("reading %u signals\n",nsig);
  while ((to == 0 || from < to) && getvec(datum) >= 0) {
    for (i = 0; i < nsig; i++){
      if (nSamples >= maxSamples) {
	/*Reallocate memory */
	mexPrintf("nSamples=%u\n",nSamples);
	maxSamples=maxSamples+ (reallocIncrement * nsig );
	mexPrintf("reallocating output matrix to %u\n", maxSamples);
	if ((dynamicData = mxRealloc(dynamicData, maxSamples * sizeof(double))) == NULL) {
	  mexPrintf("Unable to allocate enough memory to read record!");
	  mxFree(dynamicData);
	  return;
	}
      }
      /* Convert data to physical units */
      dynamicData[nSamples] =( (double) datum[sig[i]] - info[sig[i]].baseline ) / info[sig[i]].gain;
    }/* End of Channel loop */

    nSamples++;
  }
  mexPrintf("datum[0]=%f datum[1]=%f\n",datum[sig[0]],datum[sig[1]]);
  return;
}





/* Helper function to validate inputs */
/* [signal] = mexrdsamp(recordName,signaList,N,N0,rawUnits,highResolution) */
void checkinputs(int ninputs, const mxArray* inputs[]){

  if (ninputs < 6){
    mexErrMsgIdAndTxt("MATLAB:mexrdsamp:toomanyinputs",
		      "Too many input variables.");
  }
  if (ninputs < 1) {
    mexErrMsgIdAndTxt("MATLAB:mexrdsamp:missingrecordName",
		       "Record Name required.");
  }

  for(i=0; i<ninputs; i++){ 
    switch (argnum){
    case 0:
      if(!mxIsChar(prhs[0])){
	mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidrecordName",
			  "Record Name must be a string.");
      }
      break;
    case 1:
      break;
    
    
    }
  }

}





/* Gateway Function */
/* Matlab call: [signal] = mexrdsamp(recordName,signaList,N,N0,rawUnits,highResolution) */
void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray* prhs[] ){

  int argc=3; /* Minimum: rdsamp -r recordname */ 

  
  
  /* Check and capture input and output arguments */
  
 
  
  
  
  
  
  
  /* ADD: Check that recordname is a string */

  /* End of checking inputs/outputs */


  /* argv structure: rdsamp -r record -f -t -s -P*/
  char *argv[argc]; 
  

  /* Get record name */
  char *rec_name;
  size_t reclen;
  reclen = mxGetN(prhs[0])*sizeof(mxChar)+1;
  rec_name = malloc(sizeof(long));

  int status;
  status = mxGetString(prhs[0], rec_name, (mwSize)reclen);


  /* Get other specified input variables */

  


  /* Should actually set arguments... 
  
  int argc=5;
  char *argv[argc];
  argv[0]="canbewhatevergargehere";
  argv[1] = "-r";
  argv[2] = rec_name;
  argv[3] = "-t";
  argv[4] = "s5";

  */ 

  /*Call WFDB Code */
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


