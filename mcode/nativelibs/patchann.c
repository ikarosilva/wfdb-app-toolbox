/* file: patchann.c		G. Moody	27 March 2013
				Last revised:	 5 April 2013
Create or patch a PhysioBank-compatible annotation file from a LightWAVE editlog

Copyright (C) 2012-2013 George B. Moody

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place - Suite 330, Boston, MA 02111-1307, USA.

You may contact the author by e-mail (george@mit.edu) or postal mail
(MIT Room E25-505A, Cambridge, MA 02139 USA).  For updates to this software,
please visit PhysioNet (http://www.physionet.org/).
_______________________________________________________________________________

This program reads a LightWAVE edit log from its standard input and creates a
PhysioBank annotation file containing the original annotations (if any), with
additions, deletions, and modifications specified by the edit log.  Think of it
as 'patch' [http://en.wikipedia.org/wiki/Patch_(Unix)]for annotation files.

The first line of the edit log specifies the record and annotator names,
allowing this program to find the original annotations automatically, if they
exist, and to load them into an in-memory annotation array.  The program then
applies the entries of the edit log one at a time, inserting additional
annotations into the array and deleting annotations as needed from the array.
An edit log deletion entry results in a deletion only if the array contains an
exact match for the log entry. (If there is no match, this program issues a
warning and continues to process the remaining log entries.)  When all edit log
entries have been processed, the program writes the contents of the array to a
new annotation file.  If a set of original annotations exists, a '_' is
appended to the name of the new annotation file so that they can be
distinguished from each other.

LightWAVE edit log format spec:
    http://physionet.org/lightwave/doc/edit-log-format.html
PhysioBank annotation file format spec:
    http://physionet.org/physiotools/wag/annot-5.htm
_______________________________________________________________________________

*/

#include <stdio.h>
#include <stdlib.h>
#include <wfdb/wfdb.h>
#include <wfdb/ecgcodes.h>

/* In-memory annotation array

The in-memory annotation array is a doubly-linked list of elements, beginning
with aphead and ending with aptail.  aphead is the root element of the array
and never contains an annotation;  aptail marks the end of the array and
contains the last annotation unless the array is empty.

At all times, the contents of the array are kept in canonical order (sorted
first by time, then by chan, and then by num).  This property of the array is
established and maintained by insert_ann().  For efficiency, a 48-bit sort key
(t0) is created by insert_ann by concatenating the 32-bit time with the 8-bit
chan and the 8-bit num fields of the annotations.

Although the output annotation file is sorted in canonical order, note that
this program does not require that its inputs (neither the original annotation
file or the edit log) are in canonical order, so it is not necessary to use
sortann to reorder either its input or its output.
*/

struct ax {		/* in-memory annotation array structure */
    long long t0;	/* array is ordered by t0 (48 bits needed) */
    int anntyp;		/* annotation type, as in WFDB_Annotation */
    char subtyp;	/* annotation subtype, as in WFDB_Annotation */
    char *aux;		/* annotation aux string, as in WFDB_Annotation */
    struct ax *next, *prev;  /* successor and predecessor pointers */
};

struct ax *aphead; 	/* head of annotation array (aphead->next points to the
			   first annotation; aphead does not contain an
			   annotation) */
struct ax *aptail;	/* tail of annotation array (contains an annotation
			   unless aptail = aphead, i.e., unless the array is
			   empty) */

char *record, *annotator, logtext[500];
double sps;
WFDB_Annotation annot;	/* current annotation to be processed */

int delete_ann(), insert_ann(), get_log_entry(), parse_log_header();

int main(int argc, char **argv) {
    char *oaname = NULL, *pname = argv[0];
    int n;
    struct ax *ap, *apthis;
    WFDB_Anninfo ai;

    if (parse_log_header() == 0) {
	fprintf(stderr, "%s: can't parse input file (format error)\n", pname);
	exit(1);
    }

    SUALLOC(aphead, sizeof(struct ax), 1);
    aptail = aphead;
    wfdbquiet();
    ai.name = annotator;
    ai.stat = WFDB_READ;
    SUALLOC(oaname, strlen(annotator) + 2, 1);
    sprintf(oaname, "%s_", annotator);
    if (annopen(record, &ai, 1) == 0){ /* input annotator opened successfully */
	while (getann(0, &annot) == 0)  /* read the original annotations */
	    (void)insert_ann();    /* copy them into the in-memory array */
	ai.name = oaname;	/* use oaname only if input annotator exists */
    }
    /* Failure to open the original annotation file is not an error (it simply
       means that the edit log will be used to create an entirely new set of
       annotations).  Failure to open the output is fatal, however. */
    ai.stat = WFDB_WRITE;
    if (annopen(record, &ai, 1) != 0) {  /* can't open output annotator */
	fprintf(stderr, "%s: can't write output annotation file '%s.%s\n",
		record, ai.name);
	SFREE(oaname);
	SFREE(record);
	SFREE(annotator);
	wfdbquit();
	exit(2);
    }

    /* read the edit log and merge it with the in-memory array */
    while (n = get_log_entry()) {
	switch (n) {
	  case 1: insert_ann(); break;
	  case 2: delete_ann(); break;
	  default: break;	/* warn about bad input, continue processing */
	}
    }

    /* Write the in-memory array to the output annotation file */
    ap = aphead->next;
    while (ap) {
	SFREE(ap->prev);
	annot.anntyp = ap->anntyp;
	annot.subtyp = ap->subtyp;
	annot.chan = ((ap->t0) >> 8) & 255;
	annot.num = ((ap->t0) & 255) - 128;
	annot.time = (ap->t0) >> 16;
	annot.aux = ap->aux;
	putann(0, &annot);
	ap = ap->next;
	SFREE(annot.aux);
    }
    SFREE(aptail);
    SFREE(oaname);
    SFREE(record);
    SFREE(annotator);

    wfdbquit();
    exit(0);
}

/* Get the record and annotator names, and the sampling frequency, from
   the header.  Return 1 if successful, 0 otherwise. */
int parse_log_header() {
    char *p, *q;

    /* Read and parse header line 1. */
    fgets(logtext, sizeof(logtext), stdin);

    if (strncmp(logtext, "[LWEditLog-1.0] Record ", 23)) return 0;

    for (p = q = logtext+23; *q && *q != ','; q++)
	;
    if (*q) *q = '\0';

    if (strncmp(q+1, " annotator ", 11)) return 0;
    SSTRCPY(record, p);

    for (p = q = q+12; *q && *q != ' '; q++)
	;
    if (*q) *q = '\0';
    if (*(q+1) != '(') {
	SFREE(record);
	return 0;
    }
    SSTRCPY(annotator, p);

    for (p = q = q+2; *q && *q != ' '; q++)
	;
    if (*q) *q = '\0';
    if (strncmp(q+1, "samples/second)", 15)) {
	SFREE(record);
	SFREE(annotator);
	return 0;
    }
    sscanf(p, "%lf", &sps);

    /* Read header line 2, which should be empty. */
    fgets(logtext, sizeof(logtext), stdin);
    if (*logtext != '\r' && *logtext != '\n') {
	SFREE(record);
	SFREE(annotator);
	return 0;
    }

    return 1;	/* success! */
}

int get_log_entry() {
    char p[500], *q;
    int edittype, i, j, len;
    WFDB_Time ti, tf;

    /* Read the next log entry, return 0 if no more entries. */
    if (!fgets(logtext, sizeof(logtext), stdin)) return 0;

    /* Fill in the default fields of annot. */
    annot.anntyp = NORMAL;
    annot.subtyp = annot.chan = annot.num = 0;
    annot.aux = NULL;

    /* Copy the entry to p and replace the line ending with a null (logtext will
       not be modified below). */
    len = strlen(logtext);
    strncpy(p, logtext, len + 1);
    if (p[len - 1] == '\n') {
	if (p[len - 2] == '\r') p[len - 2] = '\0';
	else p[len - 1] = '\0';
    }

    /* Identify the action associated with this log entry. */
    if (logtext[0] == '-') { edittype = 2; i = 1; } /* deletion */
    else	       { edittype = 1; i = 0; } /* insertion */

    /* Parse the rest of the entry to fill in the time and any non-default
       fields of annot. */

    /* find and isolate digits */
    q = p+i;
    for ( ; p[i]; i++)
	if (p[i] < '0' || p[i] > '9') break;
    p[i] = '\0';
    if (strlen(q) == 0 || sscanf(q, "%ld", &ti) != 1 || ti < 0) return -1;
    annot.time = ti;
    
    /* is there anything else on this line? */
    if (logtext[i] == '\r' || logtext[i] == '\n')
	return edittype;	/* nothing more to parse */

    else if (logtext[i] != ',' && logtext[i] != '-') return -1;
	/* something else is there but it can't be parsed */

    else if (logtext[i] == '-') {
	/* it looks like tf is there */
	q = p + i+1;
	for (++i; p[i]; i++)
	    if (p[i] < '0' || p[i] > '9') break;
	p[i] = '\0';
	if (strlen(q) == 0 || sscanf(q, "%ld", &tf) != 1 || tf < ti)
	    return -1;

	/* no support for tf in the WFDB library yet; warn, but continue
	   parsing the rest of this log entry */
	fprintf(stderr, "(warning): no support for tf at %ld", annot.time);

	if (logtext[i] == '\r' || logtext[i] == '\n')
	    return edittype;	/* nothing more to parse */
    }
    
    /* next should be anntype */
    q = p + i+1;
    /* look for end of anntype, but skip the first character since it
       might be '{' or ',' if a non-standard type was defined */
    for (i += 2; p[i] && p[i] != ',' && p[i] != '{'; i++)
	;
    p[i] = '\0';
    annot.anntyp = strann(q);
    if (annot.anntyp == NOTQRS) {
	/* unrecognized type string: set anntyp to NOTE, copy string to aux */
	annot.anntyp = NOTE;
	*(q-1) = strlen(q);	/* aux strings have byte count prefix */
	SSTRCPY(annot.aux, q-1);
    }
    
    /* is (subtype/chan/num) present? */
    if (logtext[i] == '{') {
	for (j = ++i; p[j] && p[j] != '/'; j++)
	    ;
	if (p[j] != '/') return -1;
	if (j > i) { p[j] = '\0'; annot.subtyp = atoi(p+i); }
	i = j+1;
	
	for (j = i; p[j] && p[j] != '/'; j++)
	    ;
	if (p[j] != '/') return -1;
	if (j > i) { p[j] = '\0'; annot.chan = atoi(p+i); }
	i = j+1;
	
	for (j = i; p[j] && p[j] != '}'; j++)
	    ;
	if (p[j] != '}') return -1;
	if (j > i) { p[j] = '\0'; annot.num = atoi(p+i); }
	i = j+1;
    }
    
    /* is aux present? */
    if (logtext[i] == ',') {
	int len = strlen(p+i+1), maxlen = 255;

	if (annot.aux) {  /* true if type was unrecognized, see above */
	    unsigned char *s = annot.aux + strlen(annot.aux) - 1;
	    p[i--] = ':';   /* prefix user-specified aux with type and colon */
	    while (s > annot.aux)
		p[i--] = *s--; /* safe (annot.aux is a substring of p[0..i]) */
	}
	len = strlen(p+i+1);
	if (len > 255) {  /* check length and truncated if necessary */
	    fprintf(stderr, "(warning): aux will be truncated at %ld",
		    annot.time);
	    len = 255;
	    p[i+len+1] == '\0';
	}
	p[i] = len;	/* aux strings have byte count prefix */
	SSTRCPY(annot.aux, p+i);
    }

    return edittype;  /* 1 (insertion), or 2 (deletion) */
}

/* Insert annot into the in-memory annotation array in time/chan/num order. */
int insert_ann() {
    struct ax *ap, *apthis;

    /* Allocate memory for the annotation to be inserted. */
    SUALLOC(apthis, sizeof(struct ax), 1);

    /* Load the fields of annot into *apthis. */
    apthis->anntyp = annot.anntyp;
    apthis->subtyp = annot.subtyp;
    apthis->t0 = (annot.time << 16) |
	((annot.chan & 255) << 8) | ((annot.num + 128) & 255);
    if (annot.aux && *(annot.aux)) SSTRCPY(apthis->aux, annot.aux);

    /* Find the correct position for *apthis and insert it there. */
    for (ap = aptail; ap; ap = ap->prev) {
	if (ap->t0 < apthis->t0) { /* insert apthis between ap and ap->next */
	    apthis->prev = ap;		/* link apthis to its predecessor ... */
	    apthis->next = ap->next;   /* and to its successor (may be null) */
	    apthis->prev->next = apthis;  /* link its predecessor to apthis */
	    if (apthis->next)	       /* if apthis has a successor ... */
		apthis->next->prev = apthis;  /* link it back to apthis */
	    else aptail = apthis;      /* otherwise apthis is now the tail */
	    break;
	}
    }
    return 1;
}

/* delete an exact match of annot, if it exists, from the in-memory array */
int delete_ann() {
    long long t0;
    struct ax *ap;

    t0 = (annot.time << 16) | ((annot.chan&255) << 8) | ((annot.num+128) & 255);
    for (ap = aptail; ap; ap = ap->prev) {
	if (t0 == ap->t0 &&
	    annot.anntyp == ap->anntyp && annot.subtyp == ap->subtyp &&
	    (!annot.aux && !ap->aux) ||
	     (annot.aux && ap->aux && !strcmp(annot.aux, ap->aux))) {
	    ap->prev->next = ap->next;     /* link predecessor to successor */
	    if (ap->next)		   /* if ap has a successor ... */
		ap->next->prev = ap->prev; /* link successor to predecessor */
	    else aptail = ap->prev; /* otherwise predecessor is now the tail */ 
	    SFREE(ap->aux);
	    SFREE(ap);
	    return 1;
	}
    }
    return 0;
}
