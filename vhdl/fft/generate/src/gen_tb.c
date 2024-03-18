#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "common.h"
//#include <math.h>

char * code_string_head_start = 
"library ieee;\n"
"use ieee.std_logic_1164.all;\n"
"entity fft_tb is\n"
"end fft_tb;\n"
"architecture test of fft_tb is\n"
"\tcomponent fft\n"
"\tport (\n"
"\t\tclk, fft_start: in std_logic;\n"
"\t\toutput_valid : out std_logic;\n"
"\t\tinA, inB : in std_logic_vector(";
char * code_string_head_midline =
" downto 0);\n"
"\t\toutA, outB: out std_logic_vector(";
char * code_string_head_end =
" downto 0));\n"
"\tend component;\n\n";

char * code_string_signals;
char * code_string_signals_end =
" downto 0) := (others =>'0');\n"
"\tsignal clk, fft_start : std_logic := '0';\n"
"\tsignal output_valid : std_logic;\n"
"begin\n"
"    fft_i: fft\n"
"    port map (\n"
"        clk => clk,\n"
"        fft_start => fft_start,\n"
"        inA => inA,\n"
"        inB => inB,\n"
"        output_valid => output_valid,\n"
"        outA => outA,\n"
"        outB => outB\n"
"    );\n"
"\tprocess begin\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '1';\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '0';\n"
"\t\tfft_start <= '1';\n";

char * code_string_inputs;
char * clock_cycle = 
"\t\twait for 1 ns;\n"
"\t\tclk <= '1';\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '0';\n";

char * code_string_run = 
"\twhile output_valid = '0' loop\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '1';\n"
"\t\twait for 1 ns;\n"
"\t\tclk <= '0';\n"
"\tend loop;\n";

int verbose = 0;
int fft_length;
int bits;
int fft_n;
char * input_file = "";

void read_input (const char* file_name, __int32_t val[], int bits, int length)
{
    FILE *numbers;
    numbers = fopen(file_name, "r");

    if (numbers == NULL){
        printf("Error reading file, try ./gen_tb /path/to/file\n");
        exit (0);
    }
    char str[60];
    fgets(str, 60, numbers);

    int read1 = 0.0;
    int read2 = 0.0;
    for (int i = 0; i < length; i++)
    {
        fscanf(numbers, "%d\t%d\n ", &read1, &read2);
        val[i] = read1<<(bits-13);
    }
    fclose(numbers);
}


char* code_string_head;
char* code_string_head_ptr;
void head_append(char* str, int len){
    strncpy(code_string_head_ptr, str, len);
    code_string_head_ptr += len;
}
void gen_code_head(){
    int length_csh_start = strlen(code_string_head_start);
    int length_csh_midline = strlen(code_string_head_midline);
    int length_csh_end = strlen(code_string_head_end);
    int width_signal = 2*bits-1;
    int length_width_signal = snprintf(NULL, 0, "%d", width_signal);

    code_string_head = malloc(length_csh_start + length_width_signal + length_csh_midline + length_width_signal + length_csh_end);
    code_string_head_ptr = code_string_head;

	head_append(code_string_head_start, length_csh_start);

    char width_str[length_width_signal+1];
    snprintf(width_str, length_width_signal+1, "%d", width_signal);
    head_append(width_str, length_width_signal);

    head_append(code_string_head_midline, length_csh_midline);

    char fft_n_str[length_width_signal+1];
    snprintf(fft_n_str, length_width_signal+1, "%d", width_signal);
    head_append(fft_n_str, length_width_signal);

    head_append(code_string_head_end, length_csh_end);
}
char * code_string_signals_ptr;
void signals_append(char *str, int len) {
    strncpy(code_string_signals_ptr , str, len); 
	code_string_signals_ptr += len;
}

void gen_code_signals(){
    int data_signal_width = 2*bits;
    int length_dsw = snprintf(NULL, 0, "%d", data_signal_width-1); //dsw = data signal width
	
	char * first_signal_str = "\tsignal inA, inB, outA, outB : std_logic_vector(";
	int length_first_signal = strlen(first_signal_str);

	int length_signals_end = strlen(code_string_signals_end);
    code_string_signals = malloc(length_first_signal + length_dsw + length_signals_end);
    code_string_signals_ptr = code_string_signals;

    signals_append(first_signal_str, length_first_signal);

    char dsw_str[length_dsw+1];
    snprintf(dsw_str, length_dsw+1, "%d", data_signal_width-1);
    signals_append(dsw_str, length_dsw);

    strncpy(code_string_signals_ptr, code_string_signals_end, length_signals_end);
}
char * code_string_inputs_ptr;
void input_append(char *str, int len) {
    strncpy(code_string_inputs_ptr , str, len); 
	code_string_inputs_ptr += len;
}
void gen_code_inputs(){
	char * assign_a_str = "\t\tinA<=\"";
	char * assign_b_str = "\t\tinB<=\"";
	int len_assign = strlen(assign_a_str);
	char * line_end_str = "\";\n";
	int len_line_end = strlen(line_end_str);
    int len_misc = len_assign + len_line_end;
    int line_length = 2*bits+len_misc;
    int len_clock_cycle = strlen(clock_cycle);
    int block_len = 2*line_length+len_clock_cycle;
    __int32_t * signal = malloc( sizeof(__int32_t) * fft_length);
    read_input(input_file ,signal, bits, fft_length);
	int total_len = sizeof(char) * ((fft_length+10 )* block_len)+1;
    code_string_inputs = malloc(total_len);
    code_string_inputs_ptr = code_string_inputs;
    for (int i = 0; i < fft_length >> 1; i++){

        input_append(assign_a_str, len_assign); 

        int2bit(0, code_string_inputs_ptr, bits);
		code_string_inputs_ptr += bits;
        int2bit(signal[2*i], code_string_inputs_ptr, bits);
		code_string_inputs_ptr += bits;

        input_append(line_end_str, len_line_end);
        input_append(assign_b_str, len_assign); 

        int2bit(0, code_string_inputs_ptr, bits);
		code_string_inputs_ptr += bits;
        int2bit(signal[2*i+1], code_string_inputs_ptr, bits);
		code_string_inputs_ptr += bits;

        input_append("\";\n", 3);

        if(i<(fft_length/2)-1) {
			input_append(clock_cycle, len_clock_cycle);
		}
        else {
			input_append("", 1);
		}

    }

        free(signal);

}

char * code_string_out_end =
" loop\n"
"        wait for 1 ns;\n"
"            clk <= '1';\n"
"            wait for 1 ns;\n"
"            clk <= '0';\n"
"        end loop;\n"
"        wait;\n"
"\tend process;\n"
"end test;\n";
char * code_string_out;
char * code_string_out_ptr;
void out_append(char * str, int len) {
    strncpy(code_string_out_ptr , str, len); 
	code_string_out_ptr += len;
}
void gen_code_out(){
    int fft_length_half = fft_length/2; //flh = fft_length_half
    int length_flh = snprintf(NULL, 0, "%d", fft_length_half);

	char * for_loop_str = "\tfor i in 0 to ";
	int length_for_loop_str = strlen(for_loop_str);
	int length_code_string_out_end = strlen(code_string_out_end);

    code_string_out = malloc(length_for_loop_str + length_flh + length_code_string_out_end);
    code_string_out_ptr = code_string_out;

    out_append(for_loop_str, length_for_loop_str);

    char flh_str[length_flh];
    snprintf(flh_str, length_flh+1, "%d", fft_length_half);
    out_append(flh_str, length_flh);

    out_append(code_string_out_end, length_code_string_out_end);
}
int main(int argc, char * argv[]){
    fft_n = 15;
    bits = 19;
    char * output_file = "fft_tb.vhdl";
    char * config_file = 0;
    for (int i = 0; i < argc; i++)
    {
        if(*(argv[i]) == '-'){
            switch(argv[i][1]){
                case 'c':
                    if(i+1>=argc){
                        if(verbose) printf("Option -c requires a positional file argument");
                        exit(EXIT_FAILURE);
                    }
					config_file = argv[++i];
                    break;
                case 'n':
                    if(i+1>=argc){
                        if(verbose) printf("Option -n requires a positional integer argument");
                        exit(EXIT_FAILURE);
                    }
                    get_int(&fft_n, argv[++i], 'n', verbose);
                    break;
                case 'b':
                    if(i+1>=argc){
                        if(verbose) printf("Option -b requires a positional integer argument");
                        exit(EXIT_FAILURE);
                    }
                    get_int(&bits, argv[++i], 'b', verbose);
                    break;
                case 'o':
                    if(i+1>=argc){
                        if(verbose) printf("Option -o requires a positional file argument");
                        exit(EXIT_FAILURE);
                    }
                    output_file = argv[++i];
                    break;
                case 'i':
                    if(i+1>=argc){
                        if(verbose) printf("Option -i requires a positional file argument");
                        exit(EXIT_FAILURE);
                    }
                    input_file = argv[++i];
                    break;
            }
        }
        else{
            output_file = argv[i];
        }
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
    

	printf("generating head section\n");
    gen_code_head();
	printf("generating signal section\n");
    gen_code_signals();
	printf("generating input section\n");
    gen_code_inputs();
	printf("generating output section\n");
    gen_code_out();

    FILE * outFile;
    outFile = fopen(output_file, "w");
    if(outFile == NULL){ 
        printf("Failed opening output file.\n");
        exit(EXIT_FAILURE);
    }
    
    fprintf(outFile, "%s%s%s%s%s", code_string_head, code_string_signals, code_string_inputs, code_string_run, code_string_out);

    fclose(outFile);

    free(code_string_head);
    free(code_string_signals);
    free(code_string_inputs);
    free(code_string_out);

    
}
