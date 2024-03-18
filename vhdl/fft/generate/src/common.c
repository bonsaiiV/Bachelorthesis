#include "common.h"

char * concat(char * s1, char *s2) {
	char *result = (char*) malloc(strlen(s1) + strlen(s2) + 1); // +1 for the null-terminator
	if (!result) return 0;
    strcpy(result, s1);
    strcat(result, s2);
    return result;
}

void int2bit(int n, char* out, int bits){
    for (;bits--;n >>= 1) 
    {
        //printf("%c\n", out[bits]);  
        out[bits] = ((n & 1) + '0');
    }
}

void get_int(int * target, char * source, char option, int verbose){
    char * p;
    *target = (int) strtol(source, &p, 10);
    if(*p != '\0'){
        if(verbose) printf("positional argument of -%c should be an int", option);
        exit(EXIT_FAILURE);
    }
}
