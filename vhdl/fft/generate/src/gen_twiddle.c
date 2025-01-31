#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <getopt.h>
#include "common.h"

static char * template = 
		"library ieee;\n"
		"use ieee.std_logic_1164.all;\n"
		"use ieee.numeric_std.all;\n\n"
		"entity rom is\n"
		"	generic(\n"
		"		width :integer:=12;\n"
		"		length :integer\n"
		"	) ;\n"
		"	port (\n"
		"	   clk: std_logic;\n"
		"	   addr: in std_logic_vector(length-1 downto 0);\n"
		"	   value: out std_logic_vector(width-1 downto 0) := (others => '0')\n"
		"	);\n"
		"end rom;\n\n"
		"architecture rom_b of rom is\n"
		"	type MEMORY is array(0 to 2**length-1) of std_logic_vector(width-1 downto 0);\n"
		"	signal rom_mem :MEMORY := (\n"
		"\t%s);\n"
		"begin\n"
		"   process(clk)\n"
		"   begin\n"
		"	   if (rising_edge(clk)) then\n"
		"		   value <= rom_mem(to_integer(unsigned(addr)));\n"
		"	   end if;\n"
		"   end process;\n"
		"end rom_b;\n";

double get_twiddle_real(int n, int i){
	return cos(-2* M_PI*i/(1<<n));
}
double get_twiddle_imag(int n, int i){
	return sin(-2* M_PI*i/(1<<n));
}

__int32_t ffix(double a, int komma_pos){
	double ret = a * (1 << komma_pos);
	return (__int32_t) ret;
}

void generate_twiddle(int n, int bits, char * ret){
	__int32_t real_twiddle_int;
	__int32_t imag_twiddle_int;
	int l_word = (2*bits+3); // 2 numbers with size = bits + leading '"', closing '"' and ','
	for (int i = 0; i < 1 << (n-1); i++)
	{
		ret[i*l_word] = '"';
		real_twiddle_int = ffix(get_twiddle_real(n,i), bits-2);
		imag_twiddle_int = ffix(get_twiddle_imag(n,i), bits-2);
		for (int pos = 0; pos < bits; pos++)
		{
			ret[i*l_word+bits-pos] = (imag_twiddle_int & 1) + '0'; // index +1 for already placed '"' -1 because pos starts at 0
			imag_twiddle_int >>= 1;
			ret[i*l_word+2*bits-pos] = (real_twiddle_int & 1) + '0'; //2* bit to target second half (real part) 
			real_twiddle_int >>= 1;
		}
		ret[i*l_word+2*bits+1] = '"';
		ret[i*l_word+2*bits+2] = ',';
	}
	ret[(1<<(n-1))*(2*bits+3)-1] = '\0';
	
}

#ifdef DEBUG
int verbose = 1;
#else
int verbose = 0;
#endif


int main(int argc, char * argv[]){
	int fft_length = 0;
	int bits = 0;
	char * output_file = NULL;
	char * config_file = NULL;
	char opt;
	while ((opt = getopt(argc, argv, "c:n:b:o:")) != -1)
	{
		switch(opt){
			case 'c':
				config_file = optarg;
			break;
			case 'n':
				get_int(&fft_length, optarg, 'n', verbose);
			break;
			case 'b':
				get_int(&bits, optarg, 'b', verbose);
			break;
			case 'o':
				output_file = optarg;
			break;
			default:
				printf("unknown option\n");
				exit(1);
			break;
		}
	}
	if (config_file){
		FILE * conf_fp = fopen(config_file, "r");
		if (!conf_fp) {
			perror("Failed opening config file");
			exit(EXIT_FAILURE);
		}
		char opt = '0';
		int val = 0;

		while(fscanf(conf_fp, "-%c %d\n ", &opt, &val) != EOF){
			switch(opt){
				case 'n':
					fft_length = val;
					break;
				case 'b':
					bits = val;
					break;
			}

		}
		fclose(conf_fp);
	}
	char * ret = malloc( sizeof(char) * (1<<(fft_length-1)) * (2*bits+3));
	generate_twiddle(fft_length, bits, ret);
	FILE* outFile = fopen(output_file, "w");
	if (outFile == NULL){
		perror("failed to open output-file");
		free(ret);
		exit(EXIT_FAILURE);
	}
	fprintf(outFile, template, ret);
	fclose(outFile);
	free(ret);
	
}
