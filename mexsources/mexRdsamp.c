/* Modified version of RDSAMP.C:
 *
 *http://www.physionet.org/physiotools/wfdb/app/rdsamp.c
 *
 *The modification are done in order to make it compatible with
 *MATLAB MEX.
 *
 *Create by Ikaro Silva 2014
 *
 *
 *This assumes that <wfdb.h> is already in that path during compilation
 *
 */

/*Overwrite printf statements with MEX equivalent
 *
 */

#include <stdio.h>
#include <malloc.h>
#include "matrix.h"

double* dynamicData;
unsigned long nSamples;
long nsig;
long maxSamples =2000000;
long reallocIncrement= 1000000;   /* allow the input buffer to grow (the increment is arbitrary) */
/* input data buffer; to be allocated and returned
 * channel samples will be interleaved
 */

void rdsamp(int argc, char *argv[]){
	char* pname ="mexRdsamp1";
	char *record = NULL, *search = NULL;
	char *invalid, speriod[16], tustr[16];
	int  highres = 0, i, isiglist, nosig = 0, s,
	*sig = NULL;
	WFDB_Frequency freq;
	WFDB_Sample *datum;
	WFDB_Siginfo *info;
	WFDB_Time from = 0L, maxl = 0L, to = 0L;
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
				mexPrintf( "%s: max output length must follow -l\n",
						pname);
				return;
			}
			maxl = i;
			break;
		case 'r':	/* record name */
			if (++i >= argc) {
				mexPrintf( "%s: record name must follow -r\n",
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
				mexPrintf( "%s: signal list must follow -s\n",
						pname);
				return;
			}
			break;
		case 'S':	/* search for valid sample of specified signal */
			if (++i >= argc) {
				mexPrintf(
						"%s: signal name or number must follow -S\n",
						pname);
				return;
			}
			search = argv[i];
			break;
		case 't':	/* end time */
			if (++i >= argc) {
				mexPrintf( "%s: time must follow -t\n",pname);
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
		mexPrintf("No record name\n");
		return;
	}

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

	mexPrintf("reading from %u  to %u \n",from,to);
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
			/*dynamicData[nSamples]
			 		 =( (double) datum[sig[i]] - info[sig[i]].baseline )
			 		  / info[sig[i]].gain;
			 */

		}/* End of Channel loop */

		nSamples++;
	}
	mexPrintf("datum[0]=%f datum[1]=%f\n",datum[sig[0]],datum[sig[1]]);
	return;
}
