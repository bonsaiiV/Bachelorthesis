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
"    component fft\n"
"    port (\n"
"       clk, fft_start: in std_logic;\n"
"       output_valid : out std_logic;\n"
"       inA, inB : in std_logic_vector(";
char * code_string_head_midline =
" downto 0);\n"
"       outA, outB: out std_logic_vector(";
char * code_string_head_end =
" downto 0));\n"
"    end component;\n";

char * code_string_signals;
char * code_string_signals_end =
" downto 0) := (others =>'0');\n"
"    signal clk, fft_start : std_logic := '0';\n"
"    signal output_valid : std_logic;\n"
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
"   process begin\n"
"        wait for 1 ns;\n"
"        clk <= '1';\n"
"        wait for 1 ns;\n"
"        clk <= '0';\n"
"        fft_start <= '1';\n";

char * code_string_inputs;
char * clock_cycle = 
"wait for 1 ns;\n"
"clk <= '1';\n"
"wait for 1 ns;\n"
"clk <= '0';\n";

char * code_string_run = 
"while output_valid = '0' loop\n"
"            wait for 1 ns;\n"
"            clk <= '1';\n"
"            wait for 1 ns;\n"
"            clk <= '0';\n"
"        end loop;\n";

char * code_string_out;
char * code_string_out_end =
" loop\n"
"        wait for 1 ns;\n"
"            clk <= '1';\n"
"            wait for 1 ns;\n"
"            clk <= '0';\n"
"        end loop;\n"
"        wait;\n"
"    end process;\n"
"end test;\n";

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

void gen_code_signals(){
    int data_signal_width = 2*bits;
    int length_dsw = snprintf(NULL, 0, "%d", data_signal_width-1); //dsw = data signal width

    code_string_signals = malloc(47 + length_dsw + 459);
    char * code_string_signals_ptr = code_string_signals;

    strncpy(code_string_signals_ptr, "signal inA, inB, outA, outB : std_logic_vector(",47);
    code_string_signals_ptr += 47;

    char dsw_str[length_dsw+1];
    snprintf(dsw_str, length_dsw+1, "%d", data_signal_width-1);
    strncpy(code_string_signals_ptr, dsw_str, length_dsw);
    code_string_signals_ptr += length_dsw;

    strncpy(code_string_signals_ptr, code_string_signals_end, 459);
}
char * code_string_inputs_ptr;
void input_append(char *str, int len) {
    strncpy(code_string_inputs_ptr , str, len); 
}
void gen_code_inputs(){
    int len_misc = 9;
    int line_length = 2*bits+len_misc;
    int len_clock_cycle = strlen(clock_cycle);
    int total_len = 2*line_length+len_clock_cycle;
    __int32_t * signal = malloc( sizeof(__int32_t) * fft_length);
    read_input(input_file ,signal, bits, fft_length);

    code_string_inputs = malloc(sizeof(char) * ((fft_length+10 )* total_len)+1);
    char * code_string_inputs_ptr = code_string_inputs;
    for (int i = 0; i < fft_length >> 1; i++){

        input_append("inA<=\"", 6); 

        int2bit(0, code_string_inputs_ptr, bits);
		code_string_inputs_ptr += bits;
        int2bit(signal[2*i], code_string_inputs_ptr, bits);
		code_string_inputs_ptr += bits;

        input_append("\";\n", 3);

        input_append("inB<=\"", 6); 
        int2bit(0, code_string_inputs_ptr + line_length + len_misc-3, bits);
        int2bit(signal[2*i+1], code_string_inputs_ptr + line_length + bits + len_misc-3, bits);
        strncpy(code_string_inputs_ptr+line_length+2*bits+len_misc-3, "\";\n",3);

        if(i<(fft_length/2)-1)strncpy(code_string_inputs_ptr+line_length+2*bits+len_misc,clock_cycle, 54);
        else strncpy(code_string_inputs_ptr+line_length+2*bits+len_misc,"", 1);

        code_string_inputs_ptr += total_len;
    }

        free(signal);

}
void gen_code_out(){
    int fft_length_half = fft_length/2; //flh = fft_length_half
    int length_flh = snprintf(NULL, 0, "%d", fft_length_half);

    code_string_out = malloc(22 + length_flh + 164);
    char * code_string_out_ptr = code_string_out;

    strncpy(code_string_out_ptr, "        for i in 0 to ", 22);
    code_string_out_ptr += 22;

    char flh_str[length_flh];
    snprintf(flh_str, length_flh+1, "%d", fft_length_half);
    strncpy(code_string_out_ptr, flh_str, length_flh);
    code_string_out_ptr += length_flh;

    strncpy(code_string_out_ptr, code_string_out_end, 164);
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
    

    gen_code_head();
    gen_code_signals();
    gen_code_inputs();
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
