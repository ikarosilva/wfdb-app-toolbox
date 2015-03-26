#include <jni.h>
#include <stdio.h>
#include <wfdb/wfdb.h>

getData()
{
    int i;
    WFDB_Sample v[2];
    WFDB_Siginfo s[2];

    if (isigopen("100s", s, 2) < 2)
        exit(1);
    for (i = 0; i < 10; i++) {
        if (getvec(v) < 0)
            break;
        printf("%d\t%d\n", v[0], v[1]);
    }
    exit(0);
}


JNIEXPORT void JNICALL Java_org_physionet_wfdb_jni_Rdsamp_getData(JNIEnv *env, jobject obj)
{

	getData();
	return;
}
