#include <stdlib.h>
#include <stdio.h>
#include <math.h>

char * first_part = 
        "library ieee;\n"
        "use ieee.std_logic_1164.all;\n"
        "use ieee.numeric_std.all;\n"
        "entity rom is\n"
        "    generic(\n"
        "        width :integer:=12;\n"
        "        length :integer\n"
        "    ) ;\n"
        "    port (\n"
        "        addr: in std_logic_vector(length-1 downto 0);\n"
        "        value: out std_logic_vector(width-1 downto 0)\n"
        "    );\n"
        "end rom;\n"
        "architecture rom_b of rom is\n"
        "    type MEMORY is array(0 to 2**length-1) of std_logic_vector(width-1 downto 0);\n"
        "    signal rom_mem :MEMORY :=(\n";
char * second_part =
        ");\n"
        "attribute rom_style : string;\n"
        "   attribute rom_style of rom_mem : signal is \"block\";"
        "begin\n"
        "    value <= rom_mem(to_integer(unsigned(addr)));\n"
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

int generate_twiddle(int n, int bits, char * ret){
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
            ret[i*l_word+bits-pos] = imag_twiddle_int & 1 ? '1': '0'; // index +1 for already placed '"' -1 because pos starts at 0
            imag_twiddle_int >>= 1;
            ret[i*l_word+2*bits-pos] = real_twiddle_int & 1 ? '1': '0'; //2* bit to target second half (real part) 
            real_twiddle_int >>= 1;
        }
        ret[i*l_word+2*bits+1] = '"';
        ret[i*l_word+2*bits+2] = ',';
    }
    ret[(1<<(n-1))*(2*bits+3)-1] = '\0';
    
}




int verbose = 0;

void get_int(int * target, char * source, char option){
    char * p;
    *target = (int) strtol(source, &p, 10);
    if(*p != '\0'){
        if(verbose) printf("positional argument of -%c should be an int", option);
        exit(EXIT_FAILURE);
    }
}

int main(int argc, char * argv[]){
    int fft_length = 0;
    int bits = 0;
    char * output_file = 0;
    for (int i = 0; i < argc; i++)
    {
        if(*(argv[i]) == '-'){
            switch(argv[i][1]){
                case 'n':
                    if(i+1>=argc){
                        if(verbose) printf("Option -n requires a positional integer argument"); //n is the length of a burst
                        exit(EXIT_FAILURE);
                    }
                    get_int(&fft_length, argv[i+1], 'n');
                    i++;
                    break;
                case 'b':
                    if(i+1>=argc){
                        if(verbose) printf("Option -b requires a positional integer argument"); //b is the accuracy in bits of the twiddle factors: size = (2*b) as it is complex
                        exit(EXIT_FAILURE);
                    }
                    get_int(&bits, argv[i+1], 'b');
                    i++;
                    break;
            }
        }
        else{
            output_file = argv[i];
        }
    }
    char * ret = malloc( sizeof(char) * (1<<(fft_length-1)) * (2*bits+3));
    generate_twiddle(fft_length, bits, ret);
	FILE * outFile;
	outFile = fopen(output_file, "w");
	if (outFile == NULL){
		printf("failed to open output-file");
		exit(EXIT_FAILURE);
	}
    fprintf(outFile, "%s%s%s",first_part,ret,second_part);
	fclose(outFile);
    free(ret);
    
}
