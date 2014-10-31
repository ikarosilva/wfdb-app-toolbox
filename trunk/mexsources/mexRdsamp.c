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

char *pname;
long maxSamples = 0L;
int reallocIncrement= 50000;   /* allow the input buffer to grow (the increment is arbitrary) */
/* input data buffer; to be allocated and returned
 * channel samples will be interleaved
 */

main(int argc, char *argv[],long *input_data,unsigned long *nSamples,long *nsig)
{
	pname =argv[0];
	*nSamples = 0L; /* Number of samples read */
	char *record = NULL, *search = NULL, *prog_name();
	char *invalid, speriod[16], tustr[16];
	int  highres = 0, i, isiglist, nosig = 0, s,
			*sig = NULL;
	WFDB_Frequency freq;
	WFDB_Sample *sample;
	WFDB_Siginfo *info;
	WFDB_Time from = 0L, maxl = 0L, to = 0L;

	for (i = 1 ; i < argc; i++) {
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
	if ((*nsig = isigopen(record, NULL, 0)) <= 0) return;
	if ((sample = malloc(*nsig * sizeof(WFDB_Sample))) == NULL ||
			(info = malloc(*nsig * sizeof(WFDB_Siginfo))) == NULL) {
		mexPrintf( "%s: insufficient memory\n", pname);
		return;
	}
	if ((*nsig = isigopen(record, info, *nsig)) <= 0)
		return;
	for (i = 0; i < *nsig; i++)
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
		*nsig = nosig;
	}
	else {	/* print samples from all signals */
		if ((sig = (int *)malloc((unsigned)(*nsig)*sizeof(int))) == NULL) {
			mexPrintf( "%s: insufficient memory\n", pname);
			return;
		}
		for (i = 0; i < *nsig; i++)
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
	long *tmp;
	while ((to == 0L || from < to) && getvec(sample) >= 0) {
		for (i = 0; i < *nsig; i++){
			if (*nSamples >= maxSamples) {
				/*Reallocate memory */
				if ((tmp = realloc(input_data, maxSamples * sizeof(long))) == NULL) {
					mexPrintf("Unable to allocate enough memory to read record!");
					free(input_data);
					free(tmp);
					return;
				}
				input_data = tmp;
			}
			input_data[*nSamples] = (long) sample[sig[i]];
			*nSamples++;
		}
	}
}


/*
void load_data()
{
	double y;
	while (scanf("%lf", &y) == 1) {
		if (npts >= maxdat) {
			double *s;
			if ((s = realloc(input_data, maxdat * sizeof(double))) == NULL) {
				fprintf(stderr,"corrint: insufficient memory, exiting program!");
				exit(-1);
			}
			input_data = s;
		}
		input_data[npts] = y;
		npts++;
	}
	return (npts);
}

 */
