#include <complex.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_fft_complex.h>
#define icomplex double complex
void cprint(icomplex i){
    printf("(%f + %f i)", creal(i) , cimag(i));
}


int n;
int length;
icomplex ** input_ptr;
icomplex ** output_ptr;



int reverse_bits(int x, int amount){
    int result = 0; 
    for(int i = 0; i < amount; i++){
        result = result << 1;
        result += (x & 1);
        x = x >> 1;

    }
    result += x << amount;
    return result;
}
int lookup(int index){
    //int odd = index & 1;
    //index = index >> 1;
    //index += odd << n-1;
    return reverse_bits(index, n);
    //return reverse_bits(reverse_bits(index, layer+1), n);
}
void iprint(int i){
    printf("%d, ", i);
}


int radix2_fft(icomplex * x){
    /*int divider = length;
    n = 0;
    while(divider!= 1){
        divider = divider >> 1;
        n++;
    }*/
    icomplex * output = *output_ptr;
    

    for(int k = 0; k < length; k += 2){          //0th layer is handled seperately,
        int x_e = lookup(k);                     //as it also serves to copy and permutate
        int x_o = lookup(k+1);                       
        output[k] = x[x_e] + x[x_o];
        output[k+1] = x[x_e] - x[x_o];
    }

    icomplex unitroot;

    for(int layer = 2; layer <= n; layer++){
        int elements_per_block = 1 << (layer);
        //unitroot = cexp((-I * 2 * M_PI)/elements_per_block);
        //unitroot.real = cos(2*M_PI/elements_per_block);               
        //unitroot.imag = sin(2*M_PI/elements_per_block);

        for(int block = 0; block < (1 << (n-layer) ); block++){
            
            
            for(int k = 0; k < (elements_per_block/2); k += 1){    
                unitroot = cexp(-I * 2 * M_PI*k/elements_per_block);        
                //unitroot.real = fix(cos(2*M_PI*k/elements_per_block));                //cexp((-I * 2 * M_PI)/(1 << (layer)));
                //unitroot.imag = fix(sin(2*M_PI*k/elements_per_block));
                int k_even = (block * elements_per_block)+k;
                int k_odd = (block * elements_per_block)+k+(elements_per_block/2);
                //iprint(k_odd);
                icomplex tmp = unitroot* output[k_odd];
                //printf("\ntmp:   ");
                //cprint(tmp);
                output[k_odd] = output[k_even] - tmp;
                output[k_even] = output[k_even] + tmp;
            }
        }/*
        printf("\nAfter %dth layer:\n", layer-1);
        for(int i = 0; i < length;i++){
            printf("(%d + %d i), ", output[i].real, output[i].imag);
        }*/
        
    }
}





void read_input (const char* file_name)
{
    icomplex * input = *input_ptr;
    FILE *numbers;
    numbers = fopen(file_name, "r");

    if (numbers == NULL){
        printf("Error reading file, try ./dft /path/to/file\n");
        exit (0);
    }

    double real = 0.0;
    double imag = 0.0;
    icomplex tmp;
    for (int i = 0; i < length; i++)
    {
        fscanf(numbers, "(%lf,%lf) ", &real, &imag);
        input[i] = real + imag * I;
        //input[i].real = ffix(real);
        //input[i].imag = ffix(imag);
        //input[2*i] = real;
        //input[2*i+1] = imag;
    }

    fclose(numbers);
}
int main(int argc, char *argv[]){
    n = 4;
    length = 16;
    

    icomplex * input = malloc(sizeof(icomplex)*length);
    double * input2 = malloc(sizeof(double)*2*length);
    input_ptr = &input;
    icomplex * output = malloc(sizeof(icomplex)*length);
    output_ptr = &output;

    //create inputs
    printf("\n");
    if (argc == 2)
    {
        read_input(argv[1]);
    }else{
        for(int i = 1; i <= 4; i++){
            input[i-1] = i*i;
            //input[i-1].real = fix(i*i);
        }
        for(int i = 1; i <= 4; i++){
            input[i+3] = -i*i;
            //input[i+3].real = fix(-i*i);
        }
    }

    //convert vector representation for gsl_fft
    for(int i = 0; i < length; i++){
        input2[2*i] = creal(input[i]);
        input2[2*i+1] = cimag(input[i]);
    }


    printf("\ninput:\n");
    for(int i = 0; i < length;i++){
        cprint(input[i]);
        printf(", ");
    }

    //compute ffts
    radix2_fft(input);
    gsl_fft_complex_radix2_forward(input2, 1,length);


    printf("\noutput of gsl_fft:\n");
    for(int i = 0; i < length/2;i++){
        printf("(%f + %f i)",input2[2*i], input2[2*i+1]);
        printf(", ");
    }
    printf("\noutput of implemented fft:\n");
    for(int i = 0; i < length;i++){
        cprint(output[i]);
        printf(", ");
    }

    printf("\n");
    
}