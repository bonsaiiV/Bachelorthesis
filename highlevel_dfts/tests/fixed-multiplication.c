#include "../fix_fft.h"
#include <assert.h>
#include <stdio.h>


int factor1[] = {20, 3, 16, 1649, -1, 8, -6};
int factor2[] = {13, 4, 15, 2, 12, -1, -2};
float product[] = {260, 12, 240, 3298, -12, -8, 12};
int amount_test_vals = 7;

int main() {
	int komma_pos = 19;
	float result;
	int overflow = 0;
	struct fftConfig fft_config;
	fft_config.total_bits = 32;
	fft_config.do_round = 1;
	fft_config.twiddle_bits = 21;
	for (int i = 0; i < amount_test_vals; i++) {
		result = unfix(
			fix_mul(
				ifix(factor1[i], komma_pos),
				ifix(factor2[i], komma_pos),
				fft_config,
				&overflow
			),
			komma_pos
		);	
		printf("There was an error when multipling %d and %d:\n\t"
			"expected result: %f\n\t"
			"actual result:   %f\n",
			factor1[i],
			factor2[i],
			product[i],
			result
		);
	
		assert(result == product[i]);
		/*
			printf("There was an error when multipling %d and %d:\n\t"
				"expected result: %f\n\t"
				"actual result:   %f\n",
				factor1[i],
				factor2[i],
				product[i],
				result
			);
		//*/
	}
}
