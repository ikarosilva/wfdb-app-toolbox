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
#include <string.h>
#include <malloc.h>
#include <math.h>
#include <wfdb/wfdb.h>
#include "matrix.h"
#include "mex.h"

double* dynamicData; /* GLOBAL VARIABLES??? WHY????????? */
unsigned long nSamples;
long nsig;
long maxSamples = 2000000; /* The data array allocation length (can grow) */
long reallocIncrement= 1000000;   /* allow the input buffer to grow (the increment is arbitrary) */
/* input data buffer; to be allocated and returned
 * channel samples will be interleaved
 */

/* Work function */
void rdsamp(int argc, char *argv[]){
  char* pname ="mexrdsamp";
  char *record = NULL, *search = NULL;
  char *invalid, speriod[16], tustr[16];
  int  highres = 0, i, isiglist, nosig = 0, pflag = 0, s,
    *sig = NULL;
  double MLnan=mxGetNaN();
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
  if ((nsig = isigopen(record, NULL, 0)) <= 0){
    mexPrintf("Cannot open input files\n");
    return;
  }
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



  
  /* Allocate initial elements for the output data array */
  if ( (dynamicData= mxRealloc(dynamicData,maxSamples * nsig * sizeof(double)) ) == NULL) {
    mexPrintf("Unable to allocate enough memory to read record!");
    mxFree(dynamicData);
    return;
  }


  /* Read in the data in raw units */
  while ((to == 0 || from < to) && getvec(datum) >= 0) {
    for (i = 0; i < nsig; i++){
      /* Allocate more memory if necessary */
      if (nSamples >= maxSamples) {
	mexPrintf("nSamples=%u\n",nSamples);
	maxSamples=maxSamples+ (reallocIncrement * nsig );
	mexPrintf("reallocating output matrix to %u\n", maxSamples);
	if ((dynamicData = mxRealloc(dynamicData, maxSamples * sizeof(double))) == NULL) {
	  mexPrintf("Unable to allocate enough memory to read record!");
	  mxFree(dynamicData);
	  return;
	}
      }
      /* Convert data to physical units if specified */
      if (pflag){
	if (datum[sig[i]] == WFDB_INVALID_SAMPLE){
	  dynamicData[nSamples]=MLnan; 
	}
	else{
	  dynamicData[nSamples] =( (double) datum[sig[i]] - info[sig[i]].baseline ) / info[sig[i]].gain;
	}
      }
      nSamples++;
    }
  }
  return;
}

















/* Validate the matlab user input variables.  */
/* [signal] = mexrdsamp(recordName,signalList,N,N0,rawUnits,highResolution) */
void checkMLinputs(int ninputs, const mxArray* MLinputs[], int* inputflags){

  /* Indicator of which fields are to be passed into rdsamp.  Different from argc argv which give the (number of) strings themselves. 6 Elements indicate: recordName (-r), signalList (-s), N (-t), N0 (-f), rawUnits=0 (P), highRes (H). The fields are binary except element[1] which may store the number of input signals. The extra final element is argc to be passed into rdsampInputArgs() */
  int inputfields[]={1, 0, 0, 0, 1, 0, 4}, i; 
  /* Initial default 4: rdsamp -r recordName */
  
  if (ninputs > 6){
    mexErrMsgIdAndTxt("MATLAB:mexrdsamp:toomanyinputs",
		      "Too many input variables.\nFormat: [signal] = mexrdsamp(recordName,signalList,N,N0,rawUnits,highResolution)");
  }
  if (ninputs < 1) {
    mexErrMsgIdAndTxt("MATLAB:mexrdsamp:missingrecordName",
		       "recordName required.");
  }
  
  /* Switch through the matlab input variables sequentially */
  for(i=0; i<ninputs; i++){ 
    switch (i){
    case 0: /* recordname */
      if(!mxIsChar(MLinputs[0])){
	mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidrecordName",
			  "recordName must be a string.");
      }
      break;
    case 1: /* signalList */
      if(!mxIsEmpty(MLinputs[1])){
	int nrows, ncols;
	if (!mxIsDouble(MLinputs[1])){
	  mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidsignalListtype",
			  "signalList must be a double array.");
	}
	nrows=(int)mxGetM(MLinputs[1]);
	if (nrows != 1){
	  mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidsignalListshape",
			  "signalList must be a 1xN row vector.");
	}
	ncols=(int)mxGetN(MLinputs[1]);
	inputfields[1]=ncols;
	inputfields[6]=inputfields[6]+1+ncols;


	mexPrintf("nrows: %d\n", nrows);
	mexPrintf("ncols: %d\n", ncols);
      }
      break;
    case 2: /* N */
      if(!mxIsEmpty(MLinputs[2])){
	if (!mxIsDouble(MLinputs[2]) || mxGetNumberOfElements(MLinputs[2]) != 1){
	  mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidN",
			  "N must be a 1x1 scalar.");
	}
	inputfields[2]=1;
	inputfields[6]=inputfields[6]+2;
      }
      break;
    case 3: /* N0 */
      if(!mxIsEmpty(MLinputs[3])){
	if (!mxIsDouble(MLinputs[3]) || mxGetNumberOfElements(MLinputs[3]) != 1){
	  mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidN0",
			  "N0 must be a 1x1 scalar.");
	}
	inputfields[3]=1;
	inputfields[6]=inputfields[6]+2;
      }
      break;
    case 4: /* rawUnits */
      if(!mxIsEmpty(MLinputs[4])){
	if (!mxIsDouble(MLinputs[4]) || mxGetNumberOfElements(MLinputs[4]) != 1){
	  mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidrawUnits",
			  "rawUnits must be a 1x1 scalar.");
	}
	/* Find out whether to set -P. Default is yes */
	int rawUnits=(int)mxGetScalar(MLinputs[4]);
	if (!rawUnits){ /* Remove the -P option */
	  inputfields[4]=0;
	  inputfields[6]--;
	}
      }
      break;
    case 5: /* highResolution */
      if(!mxIsEmpty(MLinputs[5])){
	if (!mxIsDouble(MLinputs[5]) || mxGetNumberOfElements(MLinputs[5]) != 1){
	  mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidhighResolution",
			  "highResolution must be a 1x1 scalar.");
	}
	/* Find out whether to set -H. Default is no */
	int highResolution=(int)mxGetScalar(MLinputs[5]);
	if (highResolution){ /* Add -H */
	  inputfields[5]=1;
	  inputfields[6]++;
	}
      }
      break;
    }
  }
  
  for (i=0;i<7;i++){
    *(inputflags+i)=inputfields[i];
  }
}








/* Create the argv array of strings to pass into rdsamp */
/* [signal] = mexrdsamp(recordName,signalList,N,N0,rawUnits,highResolution) */
void rdsampInputArgs(int *inputfields, const mxArray *MLinputs[], char *argv[]){
  
  char charto[20], charfrom[20], charsig[inputfields[1]][20], *recname;
  int argind, i;
  size_t reclen;
  unsigned long numfrom, numto; 
  
  /* Check all possible input options to add */
  /* When constructing argv, don't forget to allocate for/add the extra null */
  for (i=0;i<6;i++){
    switch (i){
      case 0:
	reclen = mxGetN(MLinputs[0])*sizeof(mxChar)+1;
	recname = (char *)malloc(sizeof(long));
	(void)mxGetString(MLinputs[0], recname, (mwSize)reclen);
	if (strcmp(recname, "")==0){
	    mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidrecordName",
			  "recordName cannot be empty.");	    
	}
	
	argv[0]=(char *)malloc(7*sizeof(char));
	argv[1]=(char *)malloc(3*sizeof(char));
	argv[2]=(char *)malloc(strlen(recname)*sizeof(char)+1);
	strcpy(argv[0], "rdsamp");
	strcpy(argv[1], "-r");
	strcpy(argv[2], recname); 
	argind=3;
	free(recname);
	break;

      case 1: /* signalList */

        if (inputfields[1]){
	  mexPrintf("in case 1...");
	  double *signalList=(double *)mxMalloc(inputfields[1]*sizeof(double));
	  int chan;
	  mxSetPr(MLinputs[1], signalList);
	  argv[argind]=(char *)malloc(3*sizeof(char));
	  strcpy(argv[argind], "-s");
	  argind++;
	  
	  for (chan=0;chan<inputfields[1];chan++){
	    sprintf(charsig[chan], "%d" , (int)signalList[chan]);
	    argv[argind+chan]=(char *)malloc(strlen(charsig[chan])*sizeof(char)+1);
	    strcpy(argv[argind+chan], charsig[chan]);
	  }
	  argind=argind+inputfields[1];
	  mxFree(signalList);
	}
	
	break;
      case 2: /* N */
	if (inputfields[2]){

	  numto=(unsigned long)mxGetScalar(MLinputs[2]);
	  sprintf(charto, "s%lu", numto);

	  argv[argind]=(char *)malloc(3*sizeof(char));
	  argv[argind+1]=(char *)malloc(strlen(charto)*sizeof(char)+1);
	  strcpy(argv[argind], "-t");
	  strcpy(argv[argind+1], charto);
	  argind=argind+2;
	}
	break;
      case 3: /* N0 */
	if (inputfields[3]){

	  numfrom=(unsigned long)mxGetScalar(MLinputs[3]);
	  sprintf(charfrom, "s%lu", numfrom);

	  argv[argind]=(char *)malloc(3*sizeof(char));
	  argv[argind+1]=(char *)malloc(strlen(charfrom)*sizeof(char)+1);
	  strcpy(argv[argind], "-f");
	  strcpy(argv[argind+1], charfrom);
	  argind=argind+2;
	}
	break;

      case 4: /* rawUnits */
	if (inputfields[4]){
	  argv[argind]=(char *)malloc(3*sizeof(char));
	  strcpy(argv[argind], "-P");
	  argind++;
	}
	break;
      case 5: /* highResolution */
	if (inputfields[5]){
	  argv[argind]=(char *)malloc(3*sizeof(char));
	  strcpy(argv[argind], "-H");	  
	}
	break;
    }
    
  }
}







/* Matlab gateway function */
/* Matlab call: [signal] = mexrdsamp(recordName,signaList,N,N0,rawUnits,highResolution) */
void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray *prhs[] ){
  
  int argc, i, inputfields[7];

  /* Check the matlab input arguments */
  checkMLinputs(nrhs, prhs, inputfields);

  for (i=0;i<7;i++){
    mexPrintf("inputfields[%d]: %d\n\n", i, inputfields[i]);
  }
  
  argc=inputfields[6];
  char *argv[argc];

  mexPrintf("\n\nReached tag 0\n");
  
  /* Create argument strings to pass into rdsamp */
  rdsampInputArgs(inputfields, prhs, argv);
  
  
  for (i=0;i<argc;i++){
    mexPrintf("argv[%d]: %s\n", i, argv[i]);
  }

  
  /* Check output arguments */

  

  /*  
  int argc=5;
  char *argv[argc];
  argv[0]="canbewhatevergargehere";
  argv[1] = "-r";
  argv[2] = rec_name;
  argv[3] = "-t";
  argv[4] = "s5";
  */ 

  mexPrintf("\n\nReached before rdsamp\n");
  
  /*Call main WFDB Code */
  rdsamp(argc,argv);


  mexPrintf("Reached after rdsamp\n");
  
  for (i=0; i<argc; i++){
    free(argv[i]);
  }

  mexPrintf("Reached tag 3\n");

  /* Create a 0-by-0 mxArray. Memory
     will be allocated dynamically by rdsamp */
  plhs[0] = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);

  /* Set output variable to the allocated memory space */
  mxSetPr(plhs[0],dynamicData);
  mxSetM(plhs[0],nSamples);
  mxSetN(plhs[0],nsig);

  mexPrintf("Reached tag 4\n");
  
  return;
}



/* To Do




- return and exit from inner loop of rdsamp. exit whole program. 

- change all mallocs, Calloc and free to mx versions. 

- Is mexrdsamp going to use environment variable wfdbpath? ..... 


 */
