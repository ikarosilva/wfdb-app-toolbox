/* Modified version of RDSAMP.C:
 *
 *http://www.physionet.org/physiotools/wfdb/app/rdsamp.c
 *
 *The modification are done in order to make it compatible and
 *efficient when called through JNI.
 *
 *Create by Ikaro Silva 2015
 *
 *
 */
#include <jni.h>
#include <stdio.h>
#include <wfdb/wfdb.h>
#include <malloc.h>
#include <stdlib.h>

JNIEXPORT void JNICALL Java_org_physionet_wfdb_jni_Rdsamp_getData(JNIEnv *env, jobject obj)
{

	getData();
	wfdbquit();
	return;
}

//void getData()(int argc, char *argv[]){
void getData(){
	char *argv[]={"-r","mitdb/100","-t","20"};
	int argc=4;
	char* pname ="rdsampjni";
	char *record = NULL, *search = NULL;
	char *invalid, speriod[16], tustr[16];
	int  highres = 0, i, isiglist, nosig = 0, s,
	*sig = NULL;
	long nsig;
	WFDB_Frequency freq;
	WFDB_Sample *datum;
	WFDB_Siginfo *info;
	long from = 0L, to = 0L;
	int* data;
	long nSamples=0;
	long maxl = 0L;
	long maxSamples =10000;
	long reallocIncrement= 1000000;   // For records with no specified lenght
	int dynamicData=0;              // allow the input buffer to grow (the increment is arbitrary)

	for(i = 0 ; i < argc; i++){
		if (*argv[i] == '-') switch (*(argv[i]+1)) {
		case 'f':	/* starting time */
			if (++i >= argc) {
				fprintf(stderr, "%s: time must follow -f\n", pname);
				exit(2);
			}
			from = i;
			break;
		case 'H':	/* select high-resolution mode */
			highres = 1;
			break;
		case 'l':	/* maximum length of output follows */
			if (++i >= argc) {
				fprintf(stderr, "%s: max output length must follow -l\n",
						pname);
				exit(2);
			}
			maxl = i;
			break;
		case 'r':	/* record name */
			if (++i >= argc) {
				fprintf(stderr, "%s: record name must follow -r\n",
						pname);
				exit(2);
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
				fprintf(stderr, "%s: signal list must follow -s\n",
						pname);
				exit(2);
			}
			break;
		case 'S':	/* search for valid sample of specified signal */
			if (++i >= argc) {
				fprintf(stderr,
						"%s: signal name or number must follow -S\n",
						pname);
				exit(2);
			}
			search = argv[i];
			break;
		case 't':	/* end time */
			if (++i >= argc) {
				fprintf(stderr, "%s: time must follow -t\n",pname);
				exit(2);
			}
			to = atoi(argv[i]);
			break;
		default:
			fprintf(stderr, "%s: unrecognized option %s\n", pname,
					argv[i]);
			exit(2);
		}
		else {
			fprintf(stderr, "%s: unrecognized argument %s\n", pname,
					argv[i]);
			exit(2);
		}
	}

	if (record == NULL) {
		fprintf(stderr,"No record name\n");
		exit(2);
	}

	if ((nsig = isigopen(record, NULL, 0)) <= 0) exit(2);

	if ((datum = malloc(nsig * sizeof(WFDB_Sample))) == NULL ||
			(info = malloc(nsig * sizeof(WFDB_Siginfo))) == NULL) {
		fprintf(stderr, "%s: insufficient memory\n", pname);
		exit(2);
	}

	if ((nsig = isigopen(record, info, nsig)) <= 0)
		exit(2);
	for (i = 0; i < nsig; i++)
		if (info[i].gain == 0.0) info[i].gain = WFDB_DEFGAIN;
	if (highres)
		setgvmode(WFDB_HIGHRES);
	freq = sampfreq(NULL);
	if (isigsettime(from) < 0)
		exit(2);
	if (nosig) {	/* print samples only from specified signals */
		if ((sig = (int *)malloc((unsigned)nosig*sizeof(int))) == NULL) {
			fprintf(stderr, "%s: insufficient memory\n", pname);
			exit(2);
		}
		for (i = 0; i < nosig; i++) {
			if ((s = findsig(argv[isiglist+i])) < 0) {
				fprintf(stderr, "%s: can't read signal '%s'\n", pname,
						argv[isiglist+i]);
				exit(2);
			}
			sig[i] = s;
		}
		nsig = nosig;
	}
	else {	/* print samples from all signals */
		if ((sig = (int *) malloc( (unsigned) nsig*sizeof(int) ) ) == NULL) {
			fprintf(stderr, "%s: insufficient memory\n", pname);
			exit(2);
		}
		for (i = 0; i < nsig; i++)
			sig[i] = i;
	}

	/* Reset 'from' if a search was requested. */
	if (search &&
			((s = findsig(search)) < 0 || (from = tnextvec(s, from)) < 0)) {
		fprintf(stderr, "%s: can't read signal '%s'\n", pname, search);
		exit(2);
	}

	/* Reset 'to' if a duration limit was specified. */
	if (maxl && (to == 0L || to > from + maxl))
		to = from + maxl;

	/* Reset to end of record if 'to' is zero (ie, undefined) */
	if( to == 0L){
		to=strtim("e");
		if(to == 0){
		 /* In this case the record has no signal length defined, so we need
		  * an expandable array
		  */
			to=maxSamples;
			dynamicData=1;
		}
	}

	/* Read in the data in raw units */
	maxl=to-from+1;
	fprintf(stderr,"creating output matrix for %u signals and %u samples\n",
			nsig,maxl);

	if ( (data= malloc(maxl * nsig * sizeof(int)) ) == NULL) {
		fprintf(stderr,"Unable to allocate enough memory to read record!");
		exit(2);
	}

	while (( (nSamples<maxl) || (dynamicData==1) ) && getvec(datum) >= 0) {
		fprintf(stdout,"\n%u:\t",nSamples);
		for (i = 0; i < nsig; i++){
			if (nSamples >= maxl) {
				/*Reallocate memory for records that did not specify number of samples*/
				maxl +=reallocIncrement;
				fprintf(stderr,"Reallocating memory for rdsampjni to %u samples\n", to);
				if ((data = realloc(data, maxl * nsig * sizeof(int))) == NULL) {
					fprintf(stderr,"Unable to allocate enough memory to read record!");
					free(data);
					exit(2);
				}
			}
			//data[nSamples] =( (double) datum[sig[i]] - info[sig[i]].baseline )
			// 		  / info[sig[i]].gain;
			fprintf(stdout,"%u\t",datum[sig[i]]);
		}/* End of Channel loop */
		nSamples++;
	}
}
