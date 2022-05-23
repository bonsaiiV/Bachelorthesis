#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_fft_complex.h>

#define real(...) __VA_ARGS__ * 2
#define imag(...) __VA_ARGS__ * 2 + 1
#define short __int64_t

#define KOMMA_POS 13            
#define TOTAL_BITS 32           //used to simulate limited byte size and different hardware
#define NORMALIZE 0             //0 or 1
#define INDEPENDENT_FIX 0       //0 or 1 

int n;
int length;
short ** input_ptr;
int verbose = 0;
__int128_t one = 1;

//returns a floating point number from fixed point
float unfix(short a){
    return (float) a / (1 << KOMMA_POS);
}

//creates a fixed point number from an integer
short ifix(int a){
    return a << KOMMA_POS;
}

//creates a fixed point number from a floating point number
short ffix(double a){
    double ret = a * (1 << KOMMA_POS);
    return (short) ret;
}

//creates a fixed point number from a floating point number
//this is used for twiddle to allow different independent ranges of accurracy 
short fix_twiddle (double a){
    if(1-INDEPENDENT_FIX) return ffix(a);
    double ret = a * (1 << (TOTAL_BITS - 2));
    return (short) ret;
}

//returns a floating point number from fixed point
//this is used for twiddle to allow different independent ranges of accurracy 
double unfix_twiddle(short a){
    if(INDEPENDENT_FIX) return (float) a / (1 << (TOTAL_BITS - 2));
    return unfix(a);
}

//multiplies a twiddle value with another fixed point number
//DONT use for another multiplication since twiddle might have a different accuracy
short fix_mul(short a, short b){
    __int128_t c;
    if(INDEPENDENT_FIX) c = ((__int128_t) a * (__int128_t) b) >> TOTAL_BITS-3;
    else c = ((__int128_t) a * (__int128_t) b) >> KOMMA_POS-1;
    b = c & 1;
    a = (c >> 1) + b;

    if(abs(a) > (one << (TOTAL_BITS-1))) printf("There was an overflow: %f\n", unfix(a));
    return (short) a;
}

//reverses bits to find location in the array
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
    return reverse_bits(index, n);
}

//calculate twiddle the implementation in vhdl might be vastly different 
short get_twiddle_real(int elements_per_block, int k){
    return fix_twiddle(cos(-2* M_PI*k/elements_per_block));
}
short get_twiddle_imag(int elements_per_block, int k){
    return fix_twiddle(sin(-2* M_PI*k/elements_per_block));
}


void butterfly(short * x, int index1, int index2, int elements_per_block, int k){
    int i1 = lookup(index1);
    int i2 = lookup(index2);
    short twiddle_real = get_twiddle_real(elements_per_block, k);
    short twiddle_imag = get_twiddle_imag(elements_per_block, k);

    //printf("twiddle:%f, %f \n", unfix_twiddle(twiddle_real),unfix_twiddle(twiddle_imag));
    short tmp_real = fix_mul(x[real(i2)], twiddle_real) - fix_mul(x[imag(i2)], twiddle_imag);
    short tmp_imag = fix_mul(x[real(i2)], twiddle_imag) + fix_mul(x[imag(i2)], twiddle_real);

    x[real(i2)] = (x[real(i1)] - tmp_real) >> NORMALIZE;
    x[imag(i2)] = (x[imag(i1)] - tmp_imag) >> NORMALIZE;
    x[real(i1)] = (x[real(i1)] + tmp_real) >> NORMALIZE;
    x[imag(i1)] = (x[imag(i1)] + tmp_imag) >> NORMALIZE;
}


int radix2_fft(short * x){
    /*int divider = length;
    n = 0;
    while(divider!= 1){
        divider = divider >> 1;
        n++;
    }*/
    
    printf("\n");
    for(int layer = 1; layer <= n; layer++){
        int elements_per_block = 1 << (layer);

        for(int block = 0; block < (1 << (n-layer) ); block++){

            for(int k = 0; k < (elements_per_block/2); k++){    
                int index_even = (block * elements_per_block) + k;
                int index_odd  = index_even + (elements_per_block/2);

                butterfly(x, index_even, index_odd, elements_per_block, k);
            }
        }
        /*
        printf("\nAfter %dth layer:\n", layer-1);
        for(int i = 0; i < length;i++){
            printf("%f + %f i, ", unfix(x[real(i)]), unfix(x[imag(i)]));
        } */
    }
}


//driver code


void read_input (const char* file_name)
{
    short * input = *input_ptr;
    FILE *numbers;
    numbers = fopen(file_name, "r");

    if (numbers == NULL){
        printf("Error reading file, try ./dft /path/to/file\n");
        exit (0);
    }

    int real = 0.0;
    int imag = 0.0;
    int tmp;
    for (int i = 0; i < length; i++)
    {
        fscanf(numbers, "%d\t%d\n ", &real, &imag);
        input[real(i)] = ifix(real - imag);
        input[imag(i)] = 0;
    }

    fclose(numbers);
}


short create_input(int length, int i){
    int F = 5;
    return ffix(sin(M_PI * i/(length/F))+ cos(M_PI * i/(length/(F-1))));
}


int main(int argc, char *argv[]){

    length = 1 << 15;
    int divisor = length;
    n = -1;
    while(divisor){
        divisor /= 2;
        n++;
    }
    

    short * input = malloc(sizeof(short)*2*length);
    double * input2 = malloc(sizeof(double)*2*length);
    input_ptr = &input;

    //create inputs
    printf("\n");
    if (argc == 2)
    {
        read_input(argv[1]);
    }else{
        for(int i = 0; i<length; i++){
            input[real(i)] = create_input(length, i);
            input[imag(i)] = 0;
        }
    }

    //convert vector representation for gsl_fft
    for(int i = 0; i < length; i++){
        input2[2*i] =  unfix(input[real(i)]);
        input2[2*i+1] = unfix(input[imag(i)]);
    }

    if(verbose){
        printf("\ninput:\n");
        for(int i = 0; i < length;i++){
            printf("%f + %f i, ", unfix(input[real(i)]), unfix(input[imag(i)]));
        }
    }

    //compute ffts
    radix2_fft(input);
    gsl_fft_complex_radix2_forward(input2, 1,length);

    if(verbose){
        printf("\noutput of gsl_fft:\n");
        for(int i = 0; i < length/2;i++){
            printf("(%f + %f i)",input2[2*i], input2[2*i+1]);
            printf(", ");
        }
        printf("\noutput of implemented fft:\n");
        for(int i = 0; i < length/2;i++){
            int pos=lookup(i);
            printf("(%f + %f i), ", unfix(input[real(pos)]), unfix(input[imag(pos)]));
        }
        printf("\n");
    }

    float average_error = 0.0;
    for(int i = 0; i < length/2; i++){
        int normalize_factor = (1 << 15) * NORMALIZE + (1-NORMALIZE);
        average_error += fabs(input2[real(i)] - normalize_factor*unfix(input[real(lookup(i))]));
        average_error += fabs(input2[imag(i)] - normalize_factor*unfix(input[imag(lookup(i))]));
    }
    average_error /= length/2;
    printf("fix-point accuracy: %d\n", KOMMA_POS);
    printf("average error: %f\n", average_error);
    
}
