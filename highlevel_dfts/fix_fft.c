#include <math.h>
#include <stdlib.h>
#include <omp.h>
#include <stdio.h>

#include "fix_fft.h"

__int128_t one = 1;


//returns a floating point number from fixed point
float unfix(long a, int komma_pos){
    return (float) a / (1 << komma_pos);
}

//creates a fixed point number from an integer
long ifix(int a, int komma_pos){
    return a << komma_pos;
}

//creates a fixed point number from a floating point number
long ffix(double a, int komma_pos){
    double ret = a * (1 << komma_pos);
    return (long) ret;
}

//multiplies a twiddle value with another fixed point number
//DONT use for another multiplication since twiddle might have a different accuracy
long fix_mul(long a, long b, struct fftConfig config, int* overflow){
    __int128_t c;
    c = ((__int128_t) a * (__int128_t) b) >> (config.twiddle_bits-(2+config.do_round));
    b = c & config.do_round;
    a = (c >> config.do_round) + b;

    if(abs(a) > (one << (config.total_bits-1))){
        //printf("There was an overflow: %f\n", unfix(a));
        (*overflow)++;
    }
    return (long) a;
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
int lookup(int index, int n){
    return reverse_bits(index, n);
}
int rotate(int index, int amount, int n){
	int length = 1 << n;
    int mask1 = length - 1 - (amount?(1 << amount):0);
    int mask2 = length -1 - mask1;
    return ((mask1 & index) >> amount) + ((mask2 & index) << (n-amount));
}

long get_twiddle_real(int elements_per_block, int k, int komma_pos){
    return ffix(cos(-2* M_PI*k/elements_per_block), komma_pos);
}
long get_twiddle_imag(int elements_per_block, int k, int komma_pos){
    return ffix(sin(-2* M_PI*k/elements_per_block), komma_pos);
}


int butterfly(
		long * x,
		int index1,
		int index2,
		int elements_per_block,
		int k,
		struct fftConfig config){
    int i1 = lookup(index1, config.n);
    int i2 = lookup(index2, config.n);
    long twiddle_real = get_twiddle_real(elements_per_block, k, config.twiddle_bits - 2);
    long twiddle_imag = get_twiddle_imag(elements_per_block, k, config.twiddle_bits - 2);
	int overflow = 0;

    //printf("twiddle:%f, %f \n", unfix_twiddle(twiddle_real),unfix_twiddle(twiddle_imag));
    long tmp_real = 
		fix_mul(
			x[real(i2)],
			twiddle_real,
			config,
			&overflow
		) - 
		fix_mul(
			x[imag(i2)],
			twiddle_imag,
			config,
			&overflow
		);
    long tmp_imag =
		fix_mul(
			x[real(i2)],
			twiddle_imag,
			config,
			&overflow
		) +
		fix_mul(
			x[imag(i2)],
			twiddle_real,
			config,
			&overflow
		);

    x[real(i2)] = (x[real(i1)] - tmp_real) >> 1;
    x[imag(i2)] = (x[imag(i1)] - tmp_imag) >> 1;
    x[real(i1)] = (x[real(i1)] + tmp_real) >> 1;
    x[imag(i1)] = (x[imag(i1)] + tmp_imag) >> 1;
	return overflow;
}


int run_fix_fft(long * x, struct fftConfig config){
    /*int divider = length;
    n = 0;
    while(divider!= 1){
        divider = divider >> 1;
        n++;
    }*/
    int overflow = 0;
    for(int layer = 1; layer <=	config.n; layer++){
        /*
        int elements_per_block = 1 << (layer);

       for(int i = 1; i < length >> 1; i++){
           int index_even = rotate(i, layer);
           int index_odd  = rotate(i+1, layer);
           butterfly(x, index_even, index_odd, elements_per_block, i%(elements_per_block/2));
       }*/


		int elements_per_block = 1 << (layer);
#ifdef MULTI_THREAD
		omp_set_num_threads(config.threads);
		#pragma omp parallel for
#endif
		for(int block = 0; block < (1 << (config.n-layer) ); block++){
			for(int k = 0; k < (elements_per_block/2); k++){    
    	        int index_even = (block * elements_per_block) + k;
    	        int index_odd  = index_even + (elements_per_block/2);
				int bfu_overflow = 0;
    	        if ((bfu_overflow = butterfly(x, index_even, index_odd, elements_per_block, k, config))){
					overflow += bfu_overflow;
				}
    	    }
    	}
    }
	return overflow;
}

