#include <stdlib.h>
#include <stdio.h>
#include <string.h>
//#include <math.h>

char * head = 
"library ieee;\n"
"use ieee.std_logic_1164.all;\n"
"entity fft_tb is\n"
"end fft_tb;\n"
"architecture test of fft_tb is\n"
"    component fft\n"
"    generic(N : integer;\n"
"            width :integer; \n"
"            width_twiddle : integer);\n"
"    port (\n"
"       clk, fft_start: in std_logic;\n"
"       output_valid : out std_logic;\n"
"       inA, inB : in std_logic_vector(2*width-1 downto 0);\n"
"       outA, outB: out std_logic_vector(2*width-1 downto 0));\n"
"    end component;\n"
"    signal clk, fft_start : std_logic := '0';\n"
"    signal inA, inB : std_logic_vector(37 downto 0) := (others =>'0');\n"
"    signal output_valid : std_logic;\n"
"    signal outA, outB : std_logic_vector(37 downto 0);\n"
"begin\n"
"    fft_i: fft\n"
"    generic map (\n"
"        width => 19,\n"
"        width_twiddle => 6,\n"
"        N => 15\n"
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
char * tail = 
"while output_valid = '0' loop\n"
"            wait for 1 ns;\n"
"            clk <= '1';\n"
"            wait for 1 ns;\n"
"            clk <= '0';\n"
"        end loop;\n"
"        for i in 0 to 16500 loop\n"
"        wait for 1 ns;\n"
"            clk <= '1';\n"
"            wait for 1 ns;\n"
"            clk <= '0';\n"
"        end loop;\n"
"        wait;\n"
"    end process;\n"
"end test;\n";
char * clock_cycle = 
"wait for 1 ns;\n"
"clk <= '1';\n"
"wait for 1 ns;\n"
"clk <= '0';\n";
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

int main(int argc, char * argv[]){
    int fft_n = 15;
    int bits = 19;
    char * output_file = "fft_tb.vhdl";
    char * input_file = "";
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
    int fft_length = (1<<fft_n);
    int len_misc = 9;
    int line_length = 2*bits+len_misc;
    int len_clock_cycle = 54;
    int total_len = 2*line_length+len_clock_cycle;
    __int32_t * signal = malloc( sizeof(__int32_t) * fft_length);
    read_input(input_file ,signal, bits, fft_length);
    char * ret = malloc(sizeof(char) * ((fft_length+10 )* total_len)+1);
    char * ret_ptr = ret;
    char * test = malloc(sizeof(char)*60);
    printf("%d\n", fft_length);
    int2bit(120, test, 19);
    test[19] = 'w';
    test[20] = '\0';
    printf("%s\n", test);
    for (int i = 0; i < fft_length >> 1; i++){
        //printf("%d\n", i);
        strncpy(ret_ptr , "inA<=\"",6); 
        int2bit(0, ret_ptr+len_misc-3, bits);
        int2bit(signal[2*i], ret_ptr+bits+len_misc-3, bits);
        strncpy(ret_ptr+2*bits+len_misc-3 , "\";\n",3);

        strncpy(ret_ptr+line_length, "inB<=\"",6); 
        int2bit(0, ret_ptr + line_length + len_misc-3, bits);
        int2bit(signal[2*i+1], ret_ptr + line_length + bits + len_misc-3, bits);
        strncpy(ret_ptr+line_length+2*bits+len_misc-3, "\";\n",3);

        if(i<fft_length-1)strncpy(ret_ptr+line_length+2*bits+len_misc,clock_cycle, 54);
        else strncpy(ret_ptr+line_length+2*bits+len_misc,"", 1);

        ret_ptr += total_len;
    }
    free(signal);
    FILE * outFile;
    outFile = fopen(output_file, "w");
    if(outFile == NULL){ 
        printf("failed opening output file");
        exit(EXIT_FAILURE);
    }
    fprintf(outFile, "%s%s%s", head, ret, tail);
    fclose(outFile);
    free(ret);
    
}