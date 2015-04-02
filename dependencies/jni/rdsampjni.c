/* Modified version of RDSAMP.C:
 *
 *http://www.physionet.org/physiotools/wfdb/app/rdsamp.c
 *
 *The modification are done in order to make it compatible and
 *efficient when called through JNI.
 *
 *Created by Ikaro Silva 2015
 *
 *

To get field signatures for the JNI API, run
 javap -classpath ../../bin/ -s -p org.physionet.wfdb.jni.Rdsamp

 */

#include <jni.h>
#include <stdio.h>
#include <wfdb/wfdb.h>
#include <malloc.h>
#include <stdlib.h>

long nSamples=0;
double fs;
int nsig;
WFDB_Siginfo *info;
int* sig = NULL;
int* data;

void getData(int argc, char *argv[]);

JNIEXPORT void JNICALL Java_org_physionet_wfdb_jni_Rdsamp_getData(JNIEnv *env, jobject this, jobjectArray Args)
{
	jobject myRdsamp=(*env)->GetObjectClass(env,this);
	jfieldID NFieldID, fsFieldID, nsigFieldID, argsField; //Single element fields
	jmethodID setBaseline, setGain, setData;
	jintArray tmpBaseline, tmpData;
	jdoubleArray tmpGain;
	int n; // temporary Loop counter variable

	//// ******* Parse arguments   *****////
	int argc = (*env)->GetArrayLength(env,Args);
	jstring str[argc];
	char* argv[argc];
	for (n=0; n<argc; n++) {
		str[n] = (jstring) (*env)->GetObjectArrayElement(env, Args, n);
		argv[n] = (*env)->GetStringUTFChars(env, str[n], 0);
		// Don't forget to call `ReleaseStringUTFChars` when you're done.
	}

	//// ******* Call WFDB Library to get Data and signal info   *****////
	getData(argc, argv);

	//Release argument strings
	for (n=0; n<argc; n++) {
		(*env)->ReleaseStringUTFChars(env,str[n],argv[n]);
	}


	//// ******* Create data array parameters that will be used to exchange data*****////
	/// Assumptions: Multichannel data is interleaved !!
	setData =  (*env)->GetMethodID(env,myRdsamp, "setRawData", "([I)V");
	if(setData ==NULL ){
		fprintf(stderr,"GetMethodID for setRawData failed! \n");
		exit(2);
	}
	int N=nsig*nSamples; //interleaved data -> N= nsig*nSamples
	tmpData = (*env)->NewIntArray(env,N);
	if(tmpData ==NULL ){
		fprintf(stderr,"Could not allocate space for Java data array! \n");
		exit(2);
	}
	//Copy array contents
	jint *dataArr = (*env)->GetIntArrayElements(env,tmpData,NULL);
	for (n = 0; n < N; n++) {
		dataArr[n] = data[n];
	}
	//Release array and call method to
	(*env)->ReleaseIntArrayElements(env,tmpData,dataArr,0);
	(*env)->CallVoidMethod(env,this,setData,tmpData);
	//Release WFDB data
	free(data);
	data=NULL;


	if(sig == NULL || info==NULL){
		fprintf(stderr,"Could not get signal information...aborting!");
		exit(2);
	}

	//// ******* Set Single Element fields in Java Class   *****////
	if((NFieldID = (*env)->GetFieldID(env,myRdsamp,"nSamples","J"))==NULL ){
		fprintf(stderr,"GetFieldID for nSamples failed");
		exit(2);
	}
	if((fsFieldID = (*env)->GetFieldID(env,myRdsamp,"fs","D"))==NULL ){
		fprintf(stderr,"GetFieldID for fs failed");
		exit(2);
	}
	if((nsigFieldID = (*env)->GetFieldID(env,myRdsamp,"nsig","I"))==NULL ){
		fprintf(stderr,"GetFieldID for nsig failed");
		exit(2);
	}
	(*env)->SetLongField(env,this,NFieldID,nSamples);
	(*env)->SetDoubleField(env,this,fsFieldID,fs);
	(*env)->SetIntField(env,this,nsigFieldID,nsig);



	//// ******* Set Baseline Array   *****////
	setBaseline =  (*env)->GetMethodID(env,myRdsamp, "setBaseline", "([I)V");
	if(setBaseline ==NULL ){
		fprintf(stderr,"GetMethodID for setBaseline failed! \n");
		exit(2);
	}
	tmpBaseline = (*env)->NewIntArray(env,nsig);
	if(tmpBaseline ==NULL ){
		fprintf(stderr,"Could not allocate space for baseline array! \n");
		exit(2);
	}
	//Copy array contents
	jint *baselineArr = (*env)->GetIntArrayElements(env,tmpBaseline,NULL);
	for (n = 0; n < nsig; n++) {
		baselineArr[n] = info[sig[n]].baseline;
	}
	//Release array and call method to
	(*env)->ReleaseIntArrayElements(env,tmpBaseline,baselineArr,0);
	(*env)->CallVoidMethod(env,this,setBaseline,tmpBaseline);



	//// ******* Set Gain Array   *****////
	setGain =  (*env)->GetMethodID(env,myRdsamp, "setGain", "([D)V");
	if(setGain ==NULL ){
		fprintf(stderr,"GetMethodID for setGain failed! \n");
		exit(2);
	}
	tmpGain = (*env)->NewDoubleArray(env,nsig);
	if(tmpGain ==NULL ){
		fprintf(stderr,"Could not allocate space for gain array! \n");
		exit(2);
	}
	//Copy array contents
	jdouble *gainArr = (*env)->GetDoubleArrayElements(env,tmpGain,NULL);
	for (n = 0; n < nsig; n++) {
		gainArr[n] = info[sig[n]].gain;
	}
	//Release array and call method to
	(*env)->ReleaseDoubleArrayElements(env,tmpGain,gainArr,0);
	(*env)->CallVoidMethod(env,this,setGain,tmpGain);



	//// ******* Clean Up!   *****////
	free(info);
	info=NULL;
	free(sig);
	sig=NULL;
	wfdbquit();
	return;

}



void getData(int argc, char *argv[]){
	char* pname ="rdsampjni";
	char *record = NULL, *search = NULL;
	char *invalid, speriod[16], tustr[16];
	int  highres = 0, i, isiglist, nosig = 0, s;
	WFDB_Sample *datum;
	long from = 0L, to = 0L;
	long maxl = 0L;
	long maxSamples =325000;
	long reallocIncrement=2*325000;   // For records with no specified length
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
	fs = sampfreq(NULL);
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

	/* Read in the data in raw ( digital ) units */
	maxl=to-from+1;
	if ( (data= malloc(maxl * nsig * sizeof(int)) ) == NULL) {
		fprintf(stderr,"Unable to allocate enough memory to read record!");
		exit(2);
	}
	while (( (nSamples<maxl) || (dynamicData==1) ) && getvec(datum) >= 0) {
		for (i = 0; i < nsig; i++){
			if (nSamples >= maxl) {
				/*Reallocate memory for records that did not specify number of samples*/
				maxl +=reallocIncrement;
				fprintf(stderr,"Reallocating memory for rdsampjni to %lu samples\n", to);
				if ((data = realloc(data, maxl * nsig * sizeof(int))) == NULL) {
					fprintf(stderr,"Unable to allocate enough memory to read record!");
					free(data);
					exit(2);
				}
			}
			//Get interleaved data
			data[(nSamples*nsig)+i]=datum[sig[i]];
		}/* End of Channel loop */
		nSamples++;
	}/* End of data array loop */
}
