#include <stdlib.h>
#include <stdio.h>
#include <string.h>
//#include <math.h>

int fft_length;
int bits;
int fft_n;
char * input_file = "";

char * code_string_head = 
"library ieee;\n"
"use ieee.std_logic_1164.all;\n"
"entity fft_tb is\n"
"end fft_tb;\n"
"architecture test of fft_tb is\n"
"    component fft\n"
"    generic(N : integer;\n"
"            width :integer);\n"
"    port (\n"
"       clk, fft_start: in std_logic;\n"
"       output_valid : out std_logic;\n"
"       inA, inB : in std_logic_vector(2*width-1 downto 0);\n"
"       outA, outB: out std_logic_vector(2*width-1 downto 0));\n"
"    end component;\n";

char * code_string_signals;
char * code_string_signals_end =
" downto 0) := (others =>'0');\n"
"    signal clk, fft_start : std_logic := '0';\n"
"    signal output_valid : std_logic;\n"
"begin\n";

char * code_string_component;
char * code_string_component_1 =
"    fft_i: fft\n"
"    generic map (\n"
"        width => ";
char * code_string_component_2 =
"\n"
"    )\n"
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

void int2bit(int n, char* out, int bits){
    for (;bits--;n >>= 1) 
    {
        //printf("%c\n", out[bits]);  
        out[bits] = ((n & 1) + '0');
    }
}

int read_input (const char* file_name, __int32_t val[], int bits, int length)
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
        val[i] = read1<<(bits-12);
    }
    fclose(numbers);
}

void get_int(int * target, char * source, char option){
    char * p;
    *target = (int) strtol(source, &p, 10);
    if(*p != '\0'){
        if(verbose) printf("positional argument of -%c should be an int", option);
        exit(EXIT_FAILURE);
    }
}
void gen_code_signals(){
    int data_signal_width = 2*bits;
    int length_dsw = snprintf(NULL, 0, "%d", data_signal_width-1); //dsw = data signal width

    code_string_signals = malloc(47 + length_dsw + 120);
    char * code_string_signals_ptr = code_string_signals;

    strncpy(code_string_signals_ptr, "signal inA, inB, outA, outB : std_logic_vector(",47);
    code_string_signals_ptr += 47;

    char dsw_str[length_dsw+1];
    snprintf(dsw_str, length_dsw+1, "%d", data_signal_width-1);
    strncpy(code_string_signals_ptr, dsw_str, length_dsw);
    code_string_signals_ptr += length_dsw;

    strncpy(code_string_signals_ptr, code_string_signals_end, 120);
}
void gen_code_component(){
    int length_width = snprintf(NULL, 0, "%d", bits-1);
    int length_n = snprintf(NULL, 0, "%d", fft_n);

    code_string_component = malloc(50 + length_width + 17 + length_n + 332);
    char * code_string_component_ptr = code_string_component;

    strncpy(code_string_component_ptr, code_string_component_1, 50);
    code_string_component_ptr += 50;

    char width_str[length_width+1];
    snprintf(width_str, length_width+1, "%d", bits-1);
    strncpy(code_string_component_ptr, width_str, length_width);
    code_string_component_ptr += length_width;

    strncpy(code_string_component_ptr, ",\n        N => ", 15);
    code_string_component_ptr += 15;

    char fft_n_str[length_n+1];
    snprintf(fft_n_str, length_n+1, "%d", fft_n);
    strncpy(code_string_component_ptr, fft_n_str, length_n);
    code_string_component_ptr += length_n;

    strncpy(code_string_component_ptr, code_string_component_2, 332);
}
void gen_code_inputs(){
    int len_misc = 9;
    int line_length = 2*bits+len_misc;
    int len_clock_cycle = 54;
    int total_len = 2*line_length+len_clock_cycle;
    __int32_t * signal = malloc( sizeof(__int32_t) * fft_length);
    read_input(input_file ,signal, bits, fft_length);

    code_string_inputs = malloc(sizeof(char) * ((fft_length+10 )* total_len)+1);
    char * code_string_inputs_ptr = code_string_inputs;
    for (int i = 0; i < fft_length >> 1; i++){
        strncpy(code_string_inputs_ptr , "inA<=\"",6); 
        int2bit(0, code_string_inputs_ptr+len_misc-3, bits);
        int2bit(signal[2*i], code_string_inputs_ptr+bits+len_misc-3, bits);
        strncpy(code_string_inputs_ptr+2*bits+len_misc-3 , "\";\n",3);

        strncpy(code_string_inputs_ptr+line_length, "inB<=\"",6); 
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
    snprintf(flh_str, length_flh, "%d", fft_length_half);
    code_string_out_ptr += length_flh;

    strncpy(code_string_out_ptr, code_string_out_end, 164);
}
int main(int argc, char * argv[]){
    fft_n = 15;
    bits = 19;
    char * output_file = "fft_tb.vhdl";
    for (int i = 0; i < argc; i++)
    {
        if(*(argv[i]) == '-'){
            switch(argv[i][1]){
                case 'n':
                    if(i+1>=argc){
                        if(verbose) printf("Option -n requires a positional integer argument");
                        exit(EXIT_FAILURE);
                    }
                    get_int(&fft_n, argv[i+1], 'n');
                    i++;
                    break;
                case 'b':
                    if(i+1>=argc){
                        if(verbose) printf("Option -b requires a positional integer argument");
                        exit(EXIT_FAILURE);
                    }
                    get_int(&bits, argv[i+1], 'b');
                    i++;
                    break;
                case 'o':
                    if(i+1>=argc){
                        if(verbose) printf("Option -o requires a positional file argument");
                        exit(EXIT_FAILURE);
                    }
                    output_file = argv[i+1];
                    i++;
                    break;
                case 'i':
                    if(i+1>=argc){
                        if(verbose) printf("Option -i requires a positional file argument");
                        exit(EXIT_FAILURE);
                    }
                    input_file = argv[i+1];
                    i++;
                    break;
            }
        }
        else{
            output_file = argv[i];
        }
    }
    fft_length = (1<<fft_n);
    
    printf("%d\n", fft_length);
    gen_code_signals();
    gen_code_component();
    gen_code_inputs();
    gen_code_out();

    FILE * outFile;
    outFile = fopen(output_file, "w");
    if(outFile == NULL){ 
        printf("failed opening output file");
        exit(EXIT_FAILURE);
    }
    
    fprintf(outFile, "%s%s%s%s%s%s", code_string_head, code_string_signals, code_string_component, code_string_inputs, code_string_run, code_string_out);

    fclose(outFile);

    free(code_string_signals);
    free(code_string_component);
    free(code_string_inputs);
    free(code_string_out);
    
}