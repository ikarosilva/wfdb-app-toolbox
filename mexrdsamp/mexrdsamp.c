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
               returned (default = all). Indices start from 1, not 0.
- N - Integer specifying the sample number at which to stop reading the record
      file. 
- N0- Integer specifying the sample number at which to start reading the record
      file. 
- rawUnits - Scalar (0 or 1) specifying whether to return the samples in raw 
             or physical values. Default = 0 for physical. 
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

/* Constants for allocating dynamic data when signal length is unknown */
#define initialAlloc 2000000 /* Initial number of elements to allocate for the data */
#define reallocIncrement 1000000   /* allow the input buffer to grow (the increment is arbitrary) */

/* Work function */
double *rdsamp(int argc, char *argv[], unsigned long *siglength, int *nsignals){

  /* Data is the final returned signal. dynamicData as initial step when no siglen in header.*/
  double *dynamicData, *Data; 
  char *record = NULL, *search = NULL;
  char *invalid, speriod[16], tustr[16];
  int  highres = 0, i, isiglist, nsig, nosig = 0, pflag = 0, s,
    *sig = NULL;
  double MLnan=mxGetNaN();
  unsigned long maxSamples = initialAlloc, nsamp=0, siglen; /* The data array allocation length (can grow). siglen is the number of samples read per channel, nsamp is the total number of samples read */
  WFDB_Frequency freq;
  WFDB_Sample *datum; 
  WFDB_Siginfo *info;
  WFDB_Time from = 0L, maxl = 0L, to = 0L;
  
  /* Reading input parameters */
  for(i = 1 ; i < argc; i++){
    if (*argv[i] == '-') switch (*(argv[i]+1)) {
      case 'f':	/* starting time */
	if (++i >= argc) {
	  mexErrMsgTxt("mexrdsamp: time must follow -f\n");
	}
	from = i;
	break;
      case 'H':	/* select high-resolution mode */
	highres = 1;
	break;
      case 'l':	/* maximum length of output follows */
	if (++i >= argc) {
	  mexErrMsgTxt("mexrdsamp: max output length must follow -l\n");
	}
	maxl = i;
	break;
      case 'P':	/* output in physical units */
	    ++pflag;
	    break;
      case 'r':	/* record name */
	if (++i >= argc) {
	  mexErrMsgTxt("mexrdsamp: record name must follow -r\n");
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
	  mexErrMsgTxt("mexrdsamp: signal list must follow -s\n");
	}
	break;
      case 'S':	/* search for valid sample of specified signal */
	if (++i >= argc) {
	  mexErrMsgTxt("mexrdsamp: signal name or number must follow -S\n");
	}
	search = argv[i];
	break;
      case 't':	/* end time */
	if (++i >= argc) {
	  mexErrMsgTxt("%s: time must follow -t\n");
	}
	to = i;
	break;
      default:
	mexErrMsgTxt("mexrdsamp: unrecognized option %s\n");
      }
    else {
      mexErrMsgTxt("mexrdsamp: unrecognized argument %s\n");
    }
  }
  if (record == NULL) {
    mexErrMsgTxt("No record name specified\n");
  }
  
  /* Read Input Files*/
  if ((nsig = isigopen(record, NULL, 0)) <= 0){
    mexErrMsgTxt("Cannot open input files\n");
  }
  if ((datum = (WFDB_Sample *)mxMalloc(nsig * sizeof(WFDB_Sample))) == NULL ||
      (info = (WFDB_Siginfo *)mxMalloc(nsig * sizeof(WFDB_Siginfo))) == NULL) {
    mexErrMsgTxt("mexrdsamp: insufficient memory\n");
  }
  
  
  if ((nsig = isigopen(record, info, nsig)) <= 0){
    mexErrMsgTxt("mexrdsamp: failed to open record");
  }

  
  for (i = 0; i < nsig; i++)
    if (info[i].gain == 0.0) info[i].gain = WFDB_DEFGAIN;
  if (highres)
    setgvmode(WFDB_HIGHRES);
  freq = sampfreq(NULL);
  if (from > 0L && (from = strtim(argv[from])) < 0L)
    from = -from;
  if (isigsettime(from) < 0)
    mexErrMsgTxt("mexrdsamp: failed to set starting samples");
  if (to > 0L && (to = strtim(argv[to])) < 0L)
    to = -to;

  
  if (nosig) {	/* print samples only from specified signals */
    if ((sig = (int *)mxMalloc((unsigned)nosig*sizeof(int))) == NULL) {
      mexErrMsgTxt("mexrdsamp: insufficient memory\n");
    }
    for (i = 0; i < nosig; i++) {
      if ((s = findsig(argv[isiglist+i])) < 0) {
	mexPrintf("mexrdsamp: can't read signal '%s'\n", argv[isiglist+i]);
	mexErrMsgTxt("Invalid signal number");
      }
      sig[i] = s;
    }
    nsig = nosig;
  }
  else {	/* print samples from all signals */
    if ((sig = (int *)mxMalloc( (unsigned) nsig*sizeof(int) ) ) == NULL) {
      mexErrMsgTxt("mexrdsamp: insufficient memory\n");
    }
    for (i = 0; i < nsig; i++)
      sig[i] = i;
  }

  /* Reset 'from' if a search was requested. */
  if (search &&
      ((s = findsig(search)) < 0 || (from = tnextvec(s, from)) < 0)) {
    mexPrintf("mexrdsamp: can't read signal '%s'\n", search);
    mexErrMsgTxt("from sample failed");
  }

  /* Reset 'to' if a duration limit was specified. */
  if (maxl > 0L && (maxl = strtim(argv[maxl])) < 0L)
    maxl = -maxl;
  if (maxl && (to == 0L || to > from + maxl))
    to = from + maxl;


  /* Signal length written in file. Preallocation. */
  if (info->nsamp){
    mexPrintf("Preallocation\n");
    if(to){ /* If the -t was specified, limit it to the signal length */
      if(to>info->nsamp){
	mexPrintf("Input sample limit N: %lu, is larger than signal length. Setting N = %lu", to, info->nsamp);
	to=info->nsamp;
      }  
    }
    else{
      to=info->nsamp;
    }
    /* Number of samples to read per signal */
    siglen=to-from;


    mexPrintf("to: %lu\nfrom: %lu\nSiglen: %lu\nnsig: %d\n", to, from, siglen, nsig);
    
    /* Allocate entire known output data array */
    if ( (Data= (double *)mxMalloc(siglen * nsig * sizeof(double)) ) == NULL) {
      mxFree(Data);
      mexErrMsgTxt("Unable to allocate enough memory to read record!");    
    }
    for (from=0; from<siglen; from++){
      (void)getvec(datum);
      for (i=0; i<nsig; i++){
	if (pflag){
	  if(datum[sig[i]]==WFDB_INVALID_SAMPLE){
	    Data[from+i*siglen]=MLnan;
	  }
	  else{
	    Data[from+i*siglen]=((double)datum[sig[i]]-info[sig[i]].baseline)/info[sig[i]].gain;
	  }
	}
	else{
	  Data[from+i*siglen]=datum[sig[i]];
	}
      }
    }
  }
  /* No signal length written in file. Dynamic allocation and copy to de-interleave. */
  else{
    mexPrintf("Dynamic Allocation");
    /* Allocate initial elements for the output data array */
    if ( (dynamicData= (double *)mxMalloc(maxSamples * nsig * sizeof(double)) ) == NULL) {
      mxFree(dynamicData);
      mexErrMsgTxt("Unable to allocate enough memory to read record!");    
    }
    unsigned long frominit=from;
    /* Read in the data */
    while ((to == 0 || from < to) && getvec(datum) >= 0) {
      from++;
      for (i = 0; i < nsig; i++){
	/* Allocate more memory if necessary */
	if (nsamp >= maxSamples) {
	  maxSamples=maxSamples+ (reallocIncrement * nsig );
	  mexPrintf("Reallocating output matrix to %u samples\n", maxSamples);
	  if ((dynamicData = (double *)mxRealloc(dynamicData, maxSamples * sizeof(double))) == NULL) {
	    mxFree(dynamicData);
	    mexErrMsgTxt("Unable to allocate enough memory to read record!");
	  }
	}
	/* Store the data */
	if (pflag){
	  if (datum[sig[i]] == WFDB_INVALID_SAMPLE){
	    dynamicData[nsamp]=MLnan; 
	  }
	  else{
	    dynamicData[nsamp] =( (double) datum[sig[i]] - info[sig[i]].baseline ) / info[sig[i]].gain;
	  }
	}
	else{
	  dynamicData[nsamp]=datum[sig[i]];
	}
	nsamp++;
      }
    }
    siglen=nsamp/nsig;

    /* Done reading data. Copy over and de-interleave the samples.*/
    if ((Data= (double *)mxMalloc(siglen * nsig * sizeof(double)) ) == NULL) {
      mxFree(Data);
      mexErrMsgTxt("Unable to allocate enough memory to read record!");    
    }
    for(from=frominit; from<(from+nsamp); from++){
      for(i=0; i<nsig; s++){
	Data[from+i*siglen]=dynamicData[from*nsig+i];
      }
    }
    mxFree(dynamicData);
  }
  
  *siglength=siglen;
  *nsignals=nsig;

  return Data;
}



/* Validate the matlab user input variables. */
/* [signal] = mexrdsamp(recordName,signalList,N,N0,rawUnits,highResolution) */
void checkMLinputs(int ninputs, const mxArray *MLinputs[], int *inputflags){

  /* Indicator of which fields are to be passed into rdsamp. Different from argc argv which give the (number of) strings themselves. 6 Elements indicate: recordName (-r), signalList (-s), N (-t), N0 (-f), rawUnits=0 (P), highRes (H). The fields are binary except element[1] which may store the number of input signals. The extra final element is argc to be passed into rdsampInputArgs() */
  int i, inputfields[]={1, 0, 0, 0, 1, 0, 4}; 
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
	if (rawUnits){ /* Remove the -P option if they want raw units */
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
  for (i=0;i<6;i++){
    switch (i){
      case 0:
	reclen = mxGetN(MLinputs[0])*sizeof(mxChar)+1;
	recname = (char *)mxMalloc(sizeof(long));
	(void)mxGetString(MLinputs[0], recname, (mwSize)reclen);
	if (strcmp(recname, "")==0){
	    mexErrMsgIdAndTxt("MATLAB:mexrdsamp:invalidrecordName",
			  "recordName cannot be empty.");	    
	}
	
	argv[0]=(char *)mxMalloc(7*sizeof(char));
	argv[1]=(char *)mxMalloc(3*sizeof(char));
	argv[2]=(char *)mxMalloc(strlen(recname)*sizeof(char)+1);
	strcpy(argv[0], "rdsamp");
	strcpy(argv[1], "-r");
	strcpy(argv[2], recname); 
	argind=3;
	mxFree(recname);
	break;

      case 1: /* signalList */

        if (inputfields[1]){
	  /*double *signalList=(double *)mxMalloc(inputfields[1]*sizeof(double)); */
	  double *signalList;
	  int chan;
	  
	  signalList=mxGetPr(MLinputs[1]);
	  
	  argv[argind]=(char *)mxMalloc(3*sizeof(char));
	  strcpy(argv[argind], "-s");
	  argind++;
	  
	  for (chan=0;chan<inputfields[1];chan++){
	    sprintf(charsig[chan], "%d" , ((int)(signalList[chan])-1)); /* -1 for matlab to c */
	    argv[argind+chan]=(char *)mxMalloc(strlen(charsig[chan])*sizeof(char)+1);
	    strcpy(argv[argind+chan], charsig[chan]);
	  }
	  argind=argind+inputfields[1];
	}
	
	break;
      case 2: /* N */
	if (inputfields[2]){

	  numto=(unsigned long)mxGetScalar(MLinputs[2]);
	  sprintf(charto, "s%lu", numto);

	  argv[argind]=(char *)mxMalloc(3*sizeof(char));
	  argv[argind+1]=(char *)mxMalloc(strlen(charto)*sizeof(char)+1);
	  strcpy(argv[argind], "-t");
	  strcpy(argv[argind+1], charto);
	  argind=argind+2;
	}
	break;
      case 3: /* N0 */
	if (inputfields[3]){

	  numfrom=(unsigned long)mxGetScalar(MLinputs[3]);
	  sprintf(charfrom, "s%lu", numfrom);

	  argv[argind]=(char *)mxMalloc(3*sizeof(char));
	  argv[argind+1]=(char *)mxMalloc(strlen(charfrom)*sizeof(char)+1);
	  strcpy(argv[argind], "-f");
	  strcpy(argv[argind+1], charfrom);
	  argind=argind+2;
	}
	break;

      case 4: /* rawUnits */
	if (inputfields[4]){
	  argv[argind]=(char *)mxMalloc(3*sizeof(char));
	  strcpy(argv[argind], "-P");
	  argind++;
	}
	break;
      case 5: /* highResolution */
	if (inputfields[5]){
	  argv[argind]=(char *)mxMalloc(3*sizeof(char));
	  strcpy(argv[argind], "-H");	  
	}
	break;
    }
  }
}







/* Matlab gateway function */
/* Matlab call: [signal] = mexrdsamp(recordName,signaList,N,N0,rawUnits,highResolution) */
void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray *prhs[]){
  
  double *Data; /* Array of data */
  unsigned long siglen=0; /* Number of samples read per channel*/
  int nsig; /* Number of signals/channels output */
  int argc, i, inputfields[7];
  
  /* Check the matlab input arguments */
  checkMLinputs(nrhs, prhs, inputfields);

  for (i=0;i<7;i++){
    mexPrintf("inputfields[%d]: %d\n\n", i, inputfields[i]);
  }
  
  argc=inputfields[6];
  char *argv[argc];
  
  /* Create argument strings to pass into rdsamp */
  rdsampInputArgs(inputfields, prhs, argv);
  
  
  for (i=0;i<argc;i++){
    mexPrintf("argv[%d]: %s\n", i, argv[i]);
  }


  /*Call main WFDB Code */
  Data=rdsamp(argc,argv, &siglen, &nsig);
  
  for (i=0; i<argc; i++){
    mxFree(argv[i]);
  }

  
  /* Create a 0-by-0 output mxArray */
  plhs[0] = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);

  /* Set output variable to the allocated memory space */
  mxSetPr(plhs[0], Data); /* SetPr used by Ikaro, for reshaping? */
  /* Data = mxGetPr(plhs[0]); */ /* GetPr used in example*/

  /* Reshape the output matrix*/
  mxSetM(plhs[0], siglen);
  mxSetN(plhs[0], nsig);

  wfdbquit();
  return;
}



/* To Do

- Is mexrdsamp going to use environment variable wfdbpath? ..... 

- Make sure from and to are +ve. Also make sure from<to.  

 */
