#include <stdio.h>
#include <stdlib.h>
#include <complex.h>
#include <math.h>

int quotient = 0;

void iprint(int i){
    printf("%d\n", i);
}

int ipow(int b, int e){
    //iprint(e);
    int res = 1;
    for(int i = 0; i < e; i++){
        res= quotient?(res*b)%quotient:(res*b);
        //iprint(res);
    }
    return res;
}


int dft2(int * x, int length){
    int divider = length;
    int n = 0;
    while(divider!= 1){
        divider = divider >> 1;
        n++;
    }
    int unitroot = ipow(4,3);
    quotient = ipow(unitroot,n) +1;
    printf("%d, %d\n", quotient, unitroot);
    int * out = malloc(sizeof(int)*length);
    for(int i = 0; i < length; i++){
        out[i] = 0;

        for(int j = 0; j < length; j++){
            //printf("%d, i: %d, j: %d\n",ipow(unitroot, i*j), i, j);
            out[i] = (out[i] + x[j] * (ipow(unitroot, i*j)))%quotient;
        }
        if(2*out[i] > quotient) out[i] -= quotient;
        printf("\n%d \n\n", out[i]);
    }
    return 1;
}


int dft(int * x, int length){
    double complex unitroot = cexp((-I * 2 * M_PI)/length);
    double complex * out = malloc(sizeof(double complex)*length);
    for(int i = 0; i < length; i++){
        out[i] = 0;

        for(int j = 0; j < length; j++){
             out[i] += x[j] * cpow(unitroot, i*j);
        }
        printf("%f + %f i\n", creal(out[i]), cimag(out[i]));
    }
    return 1;
}

int main(){
    
    int vector1[] = {1,4,9,16};
    dft(vector1, 4);
    printf("\n");
    dft2(vector1, 4);
    iprint((16777216 + 1)%quotient); 
}


