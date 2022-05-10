#include <stdio.h>
#define fixed_point_acc 0
#define icomplex struct _complex

struct _complex{
    int real;
    int imag;
};

struct _complex add(struct _complex a, struct _complex b){
    struct _complex sum;
    sum.real = a.real + b.real;
    sum.imag = a.imag + b.imag;
    return sum;
}

struct _complex sub(struct _complex a, struct _complex b){
    struct _complex diff;
    diff.real = a.real - b.real;
    diff.imag = a.imag - b.imag;
    return diff;
}

int fix(int a){
    return a << fixed_point_acc;
}

struct _complex mult(struct _complex a, struct _complex b){
    struct _complex product;
    product.real = (a.real * b.real - a.imag * b.imag) >> fixed_point_acc;
    product.imag = (a.real * b.imag - a.imag * b.real) >> fixed_point_acc;
    return product;
}

void cprint(icomplex i){
    int real = i.real / 1 << fixed_point_acc;
    int imag = i.imag / 1 << fixed_point_acc;
    printf("(%d + %d i)", real , imag);
}