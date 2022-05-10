#include "mycomplex.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>



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
        output[k] = add(x[x_e] , x[x_o]);
        output[k+1] = sub(x[x_e] , x[x_o]);
    }
    printf("\nAfter 0th layer:\n");
    for(int i = 0; i < length;i++){
        printf("(%d + %d i), ", output[i].real, output[i].imag);
    }

    icomplex unitroot;

    for(int layer = 2; layer <= n; layer++){
        int elements_per_block = 1 << (layer);
        unitroot.real = cos(2*M_PI/elements_per_block);                //cexp((-I * 2 * M_PI)/(1 << (layer)));
        unitroot.imag = sin(2*M_PI/elements_per_block);

        for(int block = 0; block < (1 << (n-layer) ); block++){
            
            
            for(int k = 0; k < (elements_per_block/2); k += 1){                 
                unitroot.real = fix(cos(2*M_PI*k/elements_per_block));                //cexp((-I * 2 * M_PI)/(1 << (layer)));
                unitroot.imag = fix(sin(2*M_PI*k/elements_per_block));
                int k_even = (block * elements_per_block)+k;
                int k_odd = (block * elements_per_block)+k+(elements_per_block/2);
                iprint(k_odd);
                icomplex tmp = mult( unitroot, output[k_odd]);
                printf("\ntmp:   ");
                cprint(tmp);
                output[k_odd] = sub(output[k_even] , tmp);
                output[k_even] = add(output[k_even] , tmp);
            }
        }
        printf("\nAfter %dth layer:\n", layer-1);
        for(int i = 0; i < length;i++){
            printf("(%d + %d i), ", output[i].real, output[i].imag);
        }
        
    }
}





void read_input (const char* file_name)
{
    icomplex * input = *input_ptr;
    printf("\n");
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
        input[i].real = (int) round(real);
        input[i].imag = (int) round(imag);
        tmp = input[i];
        iprint(real);
        cprint(input[i]);
    }
    cprint(input[1]);

    fclose(numbers);
}
int main(int argc, char *argv[]){
    n = 4;
    length = 16;
    
    
    icomplex * input = malloc(sizeof(icomplex)*length);
    input_ptr = &input;
    icomplex * output = malloc(sizeof(icomplex)*length);
    output_ptr = &output;
    printf("\n");
    if (argc == 2)
    {
        read_input(argv[1]);
    }else{
        for(int i = 1; i <= 4; i++){
            (input)[i-1].real = (i*i) << fixed_point_acc;
        }
        for(int i = 1; i <= 4; i++){
            (input)[i+3].real = -(i*i) << fixed_point_acc;
        }
    }
    printf("\ninput:\n");
    for(int i = 0; i < length;i++){
        cprint(input[i]);
        printf(", ");
    }
    radix2_fft(input);
    printf("\noutput:\n");
    for(int i = 0; i < length;i++){
        cprint(output[i]);
        printf(", ");
    }

    printf("\n");
    
}