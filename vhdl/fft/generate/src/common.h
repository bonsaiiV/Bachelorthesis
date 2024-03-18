#ifndef GEN_COMMON
#define GEN_COMMON
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

char * concat(char * s1, char *s2);
void int2bit(int n, char* out, int bits);
void get_int(int * target, char * source, char option, int verbose);

#endif
