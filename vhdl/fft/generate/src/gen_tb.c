#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "common.h"
#include "getopt.h"
//#include <math.h>

static char * begin_template = 
"library ieee;\n"
"use ieee.std_logic_1164.all;\n\n"
"entity fft_tb is\n"
"end fft_tb;\n\n"
"architecture test of fft_tb is\n"
"\tcomponent fft\n"
"\tport (\n"
"\t\tclk, fft_start: in std_logic;\n"
"\t\tinA, inB : in std_logic_vector(%d downto 0);\n"
"\t\toutput_valid : out std_logic;\n"
"\t\toutA, outB: out std_logic_vector(%d downto 0));\n"
"\tend component;\n\n"
"\tsignal inA, inB, outA, outB : std_logic_vector(%d downto 0) := (others =>'0');\n"
"\tsignal clk, fft_start : std_logic := '0';\n"
"\tsignal output_valid : std_logic;\n"
"begin\n"
"\tfft_i: fft\n"
"\tport map (\n"
"\t\tclk => clk,\n"
"\t\tfft_start => fft_start,\n"
"\t\tinA => inA,\n"
"\t\tinB => inB,\n"
"\t\toutput_valid => output_valid,\n"
"\t\toutA => outA,\n"
"\t\toutB => outB\n"
"\t);\n"
"\tprocess begin\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '1';\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '0';\n"
"\t\tfft_start <= '1';\n";

char * cycle_template = 
"\t\tinA<=\"%s\";\n"
"\t\tinB<=\"%s\";\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '1';\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '0';\n";

char * end_template = 
"\t\twhile output_valid = '0' loop\n"
"\t\t\twait for 1 ns;\n"
"\t\t\tclk <= '1';\n"
"\t\t\twait for 1 ns;\n"
"\t\t\tclk <= '0';\n"
"\t\tend loop;\n"
"\t\tfor i in 0 to %d loop\n"
"\t\t\twait for 1 ns;\n"
"\t\t\tclk <= '1';\n"
"\t\t\twait for 1 ns;\n"
"\t\t\tclk <= '0';\n"
"\t\tend loop;\n"
"\t\twait;\n"
"\tend process;\n"
"end test;\n";

int verbose = 0;
int fft_length;
int bits;
int fft_n;
char * input_file = "";

void read_input (const char* file_name, __int32_t ret[], int bits, int length)
{
	FILE * data_file;

	if ((data_file = fopen(file_name, "r")) == NULL){
		perror("error reading test data");
		exit (1);
	}
	char str[60];
	fgets(str, 60, data_file);

	int channel1 = 0;
	int channel2 = 0;
	for (int i = 0; i < length; i++)
	{
		fscanf(data_file, "%d\t%d\n ", &channel1, &channel2);
		ret[i] = channel1<<(bits-13);
	}
	fclose(data_file);
}


char * gen_code_head(){
	int width_signal = 2*bits-1;
	int length_head_signal = snprintf(NULL, 0, begin_template, width_signal);

	char * ret = calloc(length_head_signal, sizeof(char));

	snprintf(ret, length_head_signal, begin_template, width_signal, width_signal, width_signal);
	return ret;
}
char * gen_code_inputs(){
	__int32_t * signal = malloc( sizeof(__int32_t) * fft_length);
	read_input(input_file, signal, bits, fft_length);

	char strA[bits + 1];
	char strB[bits + 1];
	strA[bits] = '\0';
	strB[bits] = '\0';

	int2bit(0, strA, bits);
	int2bit(0, strB, bits);

	int cycle_len = snprintf(NULL, 0, cycle_template, strA, strB);


	int total_len = sizeof(char) * (fft_length * (cycle_len) + 1);

	char * ret = malloc(total_len);
	char * tmp = ret;
	for (int i = 0; i < fft_length >> 1; i++){
		int2bit( signal[2 * i], strA, bits);
		int2bit( signal[2 * i + 1], strB, bits);
		snprintf(tmp, cycle_len+1, cycle_template, strA, strB);
		tmp += cycle_len;
	}
	free(signal);
	return ret;
}

char * gen_code_out(){
	int fft_length_half = fft_length/2;
	int length_end = snprintf(NULL, 0, end_template, fft_length_half);
	char * ret = calloc(length_end, sizeof(char));
	snprintf(ret, length_end, end_template, fft_length_half);
	return ret;
}
int main(int argc, char * argv[]){
	fft_n = 15;
	bits = 19;
	char * output_file = "fft_tb.vhdl";
	char * config_file = 0;
	char opt;
	while ((opt = getopt(argc, argv, "c:n:b:o:i:")) != -1)
	{
		switch(opt){
			case 'c':
				config_file = optarg;
			break;
			case 'n':
				get_int(&fft_n, optarg, 'n', verbose);
			break;
			case 'b':
				get_int(&bits, optarg, 'b', verbose);
			break;
			case 'o':
				output_file = optarg;
			break;
			case 'i':
				input_file = optarg;
			break;
			default:
				fprintf(stderr, "unknown option \"%c\"\n", opt);
				exit(1);
			break;
		}
	}
	if (optind < argc) {
		output_file = argv[optind];
	}
	if (config_file){
		FILE * conf_fp = fopen(config_file, "r");
		if (!conf_fp) {
			printf("Failed opening config file.\nMake sure it exists.\n");
			exit(EXIT_FAILURE);
		}
		char opt = '0';
		int val = 0;

		while(fscanf(conf_fp, "-%c %d\n ", &opt, &val) != EOF){
			switch(opt){
				case 'n':
					fft_n = val;
					break;
				case 'b':
					bits = val;
					break;
			}

		}
	}
	fft_length = (1<<fft_n);
	

	char * code_string_head = gen_code_head();
	char * code_string_inputs = gen_code_inputs();
	char * code_string_end = gen_code_out();

	FILE * outFile;
	outFile = fopen(output_file, "w");
	if(outFile == NULL){ 
		printf("of: %s\n", output_file);
		perror("failed opening output file");
		exit(EXIT_FAILURE);
	}
	
	fprintf(outFile, "%s%s%s", code_string_head, code_string_inputs, code_string_end);

	fclose(outFile);

	free(code_string_head);
	free(code_string_inputs);
	free(code_string_end);
}
