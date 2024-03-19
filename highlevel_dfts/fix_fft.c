#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_fft_complex.h>
#include <unistd.h>
#include <getopt.h>

#define real(...) __VA_ARGS__ * 2
#define imag(...) __VA_ARGS__ * 2 + 1
#define short __int64_t
#define print_e(args...) fprintf(stderr, args)

int komma_pos = 0;            
int total_bits = 32;
int twiddle_bits = 32;
int do_round = 0;           


int n = 15;
int length;

int had_overflow = 0;
int error_mode = 0;

int verbose = 0;
__int128_t one = 1;

//returns a floating point number from fixed point
float unfix(short a){
    return (float) a / (1 << komma_pos);
}

//creates a fixed point number from an integer
short ifix(int a){
    return a << komma_pos;
}

//creates a fixed point number from a floating point number
short ffix(double a){
    double ret = a * (1 << komma_pos);
    return (short) ret;
}

//creates a fixed point number from a floating point number
//this is used for twiddle to allow different independent ranges of accurracy 
short fix_twiddle (double a){
    double ret = a * (1 << (twiddle_bits - 2));
    return (short) ret;
}

//returns a floating point number from fixed point
//this is used for twiddle to allow different independent ranges of accurracy 
double unfix_twiddle(short a){
    return (float) a / (1 << (twiddle_bits - 2));;
}

//multiplies a twiddle value with another fixed point number
//DONT use for another multiplication since twiddle might have a different accuracy
short fix_mul(short a, short b){
    __int128_t c;
    c = ((__int128_t) a * (__int128_t) b) >> twiddle_bits-(2+do_round);
    b = c & do_round;
    a = (c >> do_round) + b;

    if(abs(a) > (one << (total_bits-1))){
        //printf("There was an overflow: %f\n", unfix(a));
        had_overflow++;
    }
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
int rotate(int index, int amount){
    int mask1 = length - 1 - (amount?(1 << amount):0);
    int mask2 = length -1 - mask1;
    return ((mask1 & index) >> amount) + ((mask2 & index) << (n-amount));
}

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

    x[real(i2)] = (x[real(i1)] - tmp_real) >> 1;
    x[imag(i2)] = (x[imag(i1)] - tmp_imag) >> 1;
    x[real(i1)] = (x[real(i1)] + tmp_real) >> 1;
    x[imag(i1)] = (x[imag(i1)] + tmp_imag) >> 1;
}


void radix2_fft(short * x){
    /*int divider = length;
    n = 0;
    while(divider!= 1){
        divider = divider >> 1;
        n++;
    }*/
    
    for(int layer = 1; layer <= n; layer++){
        /*
        int elements_per_block = 1 << (layer);

       for(int i = 1; i < length >> 1; i++){
           int index_even = rotate(i, layer);
           int index_odd  = rotate(i+1, layer);
           butterfly(x, index_even, index_odd, elements_per_block, i%(elements_per_block/2));
       }*/



		int elements_per_block = 1 << (layer);
		for(int block = 0; block < (1 << (n-layer) ); block++){

			for(int k = 0; k < (elements_per_block/2); k++){    
    	        int index_even = (block * elements_per_block) + k;
    	        int index_odd  = index_even + (elements_per_block/2);

    	        butterfly(x, index_even, index_odd, elements_per_block, k);
    	    }
    	}
    }
}

//driver code


void read_input (const char* file_name, int number_of_bursts, short *(*sensor1_ptr)[], short *(*sensor2_ptr)[])
{
    short **sensor1 = *sensor1_ptr;
    short **sensor2 = *sensor2_ptr;
    FILE *numbers;
    numbers = fopen(file_name, "r");

    if (numbers == NULL){
        print_e("Error reading file, try ./dft /path/to/file\n\tor use -h for additional info.\n");
        exit(EXIT_FAILURE);
    }
    char str[60];
    fgets(str, 60, numbers);

    int read1 = 0.0;
    int read2 = 0.0;
    for(int burst = 0; burst < number_of_bursts; burst++)
    {
        for (int i = 0; i < length; i++)
        {
            fscanf(numbers, "%d\t%d\n ", &read1, &read2);
            *(sensor1[burst]+real(i)) = ifix(read1);
            *(sensor1[burst]+imag(i)) = 0;
            *(sensor2[burst]+real(i)) = ifix(read2);
            *(sensor2[burst]+imag(i)) = 0;
        }
    }
    fclose(numbers);
}


short create_input(int length, int i){
    int F = 5;
    return ffix(sin(M_PI * i/(length/F))+ cos(M_PI * i/(length/(F-1))));
}

void get_int(int * target, char * source, char option){
    char * p;
    *target = (int) strtol(source, &p, 10);
    if(*p != '\0'){
        print_e("positional argument of -%c should be an int", option);
        exit(EXIT_FAILURE);
    }
}

char * help_text = 
    "This Program is designed to assist in creating an implementation\n"
	"of a fixpoint FFT on a FPGA for SNS.\n\n"
	"It can calculate a FFT using fixedpoint numbers with various accuracy.\n"
	"The result can be compared to the gsl (GNU Scientific Library) implementation,\n"
	"printed or the SNS result can be printed to be parsed to a diagram,\n"
	"using the provided python script.\n"
    "As input a file, containing two integer signals, seperated by whitespace\n"
	"should be provided.\n"
    "The first line of the input file is skipped.\n\n"
	"Available options are:\n"
    "  -h: display this text and exit\n"
    "  -b: takes 1 positional integer argument, which specifies\n"
	"      the width in bits of the input, intermediate values and result\n"
    "    default : 32\n"
    "  -n: takes 1 positional integer argumemt, which specifies the number of bursts (frames), used in the postprocessing\n"
    "  default : 1\n"
    "  -t: takes 1 positional integer argument, which specifies the width in bits of the twiddle factor.\n"
    "  default : 32\n"
    "  -e: takes no argument. Enables error mode, comparison to gsl library fft.\n"
    "  -p: takes no argument. Enables printing of FFT result. Recomended only with low amount of input for the FFT\n"
    "  -l: takes 1 positional integer argument, which specifies the length of one burst as 2^l.\n"
    "  default : 15\n\n"
    "Any argument is neither starting with \"-\" nor consumed as argument for another option, is considered the input file.\n"
    " If there are multiple input files only the last one is used.\n";

void run_print_mode(long * sensor1[]);
void run_error_mode(long * sensor1[], long * sensor2[]);
void run_default_mode(long * sensor1[], long * sensor2[], int number_of_bursts);
int main(int argc, char *argv[]){
    int number_of_bursts = 1;
    int print_mode = 0;
    int print_help = 0;
	// get options provided via commandline
	struct option longopts[] = {
		{"help", 0, 0, 'h'},
		{"length", 1, 0, 'l'},
		{"bits", 1, 0, 'b'},
		{"bursts", 1, 0, 'n'},
		{"twiddle", 1, 0, 't'},
		{0,0,0,0}};
	char * shortopts = "h?n:b:l:ept:";

	int opt;
    while ((opt = getopt_long(argc, argv, shortopts, longopts, 0)) != -1){
		switch(opt){
			case 'h':
				print_help = 1;
				break;
			case 'n':
				get_int(&number_of_bursts, optarg, opt);
				break;
			case 'b':
				get_int(&total_bits, optarg, opt);
				break;
			case 'l':
				get_int(&n, optarg, opt);
				break;
			case 't':
				get_int(&twiddle_bits, optarg, opt);
				break;
			case 'e':
				error_mode = 1;
				break;
			case 'p':
				print_mode = 1;
				break;
			default:
				print_e("unknown option %c", opt);
				exit(EXIT_FAILURE);
		}
    }
    if(print_help){
        printf("%s", help_text);
        exit(EXIT_SUCCESS);
    }

	// check arguments for correctness
	if (optind >= argc) {
		print_e("input_file is required, use -h for more info");
		exit(EXIT_FAILURE);
	}
    char * input_file = argv[optind];
	if(twiddle_bits < 3){
		print_e("twiddle needs at least 3 bits");
		exit(EXIT_FAILURE);
	}
    if(error_mode && (number_of_bursts != 1)){
        if(verbose) printf("In error_mode number of bursts need to be 1.\nDefaulting number of bursts to 1.\n");
        number_of_bursts = 1;
    }
    komma_pos = total_bits - 13;

    length = 1 << n;
    short * sensor1[number_of_bursts];
    short * sensor2[number_of_bursts];
    for(int i = 0; i < number_of_bursts; i++){
        sensor1[i] = malloc(sizeof(short)*2*length);
        sensor2[i] = malloc(sizeof(short)*2*length);
    }

    
    short * (*sensor1_ptr)[] = &sensor1;
    short * (*sensor2_ptr)[] = &sensor2;

    //create inputs
    read_input(input_file, number_of_bursts, sensor1_ptr, sensor2_ptr);
    /*
    for(int i = 0; i<length/2; i++){
        *(sensor1[0]+real(i)) = create_input(length, i);
        *(sensor1[0]+imag(i)) = 0;
        *(sensor2[0]+real(i)) = create_input(length, i);
        *(sensor2[0]+imag(i)) = 0;
    }
        for(int i = 0; i<length/2; i++){
        *(sensor1[0]+real(i+length/2)) = -1*create_input(length, i);
        *(sensor1[0]+imag(i+length/2)) = -1*0;
        *(sensor2[0]+real(i+length/2)) = -1*create_input(length, i);
        *(sensor2[0]+imag(i+length/2)) = -1*0;
    }*/


    if(print_mode){
		run_print_mode(sensor1);
    }
    else if(error_mode){
		run_error_mode(sensor1, sensor2);
    }else
    {
		run_default_mode(sensor1, sensor2, number_of_bursts);
	}
}

void run_print_mode(long * sensor1[]) {
	printf("entering print mode\n");
	for(int i = 0; i< length; i++){
		printf("%f + %fi ,",unfix(*(sensor1[0]+real(i))), unfix(*(sensor1[0]+imag(i))));
	}
	printf("\n");

	radix2_fft(sensor1[0]);
	for(int i = 0; i< length; i++){
		int ri = lookup(i);
		printf("%f + %fi ,",unfix(*(sensor1[0]+real(ri))), unfix(*(sensor1[0]+imag(ri))));
	}
	printf("\n");
}

void run_error_mode(long * sensor1[], long * sensor2[]){
	//creating results to compare
	double * sensor1_gsl;
	double * sensor2_gsl;
	sensor1_gsl = malloc(sizeof(double)*2*length);
	sensor2_gsl = malloc(sizeof(double)*2*length);
	for(int i = 0; i < length; i++){
		sensor1_gsl[real(i)] = unfix(sensor1[0][real(i)]);
		sensor1_gsl[imag(i)] = unfix(sensor1[0][imag(i)]);
		sensor2_gsl[real(i)] = unfix(sensor2[0][real(i)]);
		sensor2_gsl[imag(i)] = unfix(sensor2[0][imag(i)]);
	}
	gsl_fft_complex_radix2_forward(sensor1_gsl, 1,length);
	gsl_fft_complex_radix2_forward(sensor2_gsl, 1,length);



	radix2_fft(sensor1[0]);
	radix2_fft(sensor2[0]);




	float average_abs_error1 = 0.0;
	float average_rel_error1 = 0.0;
	float average_abs_error2 = 0.0;
	float average_rel_error2 = 0.0;
	float absolute_error;
	
	int r_index;
	int normalize_factor = (1 << 15);

	for(int i = 0; i < length/2; i++){
		r_index = lookup(i);
		absolute_error = fabs(sensor1_gsl[real(i)] - normalize_factor*unfix(*(sensor1[0]+real(r_index))));
		average_abs_error1 += absolute_error;
		average_rel_error1 += absolute_error/fmax(1.0, fabs(sensor1_gsl[real(i)]));

		absolute_error = fabs(sensor1_gsl[imag(i)] - normalize_factor*unfix(*(sensor1[0]+imag(r_index))));
		average_abs_error1 += absolute_error;
		average_rel_error1 += absolute_error/fmax(1.0, fabs(sensor1_gsl[imag(i)]));

		absolute_error = fabs(sensor2_gsl[real(i)] - normalize_factor*unfix(*(sensor2[0]+real(r_index))));
		average_abs_error2 += absolute_error;
		average_rel_error2 += absolute_error/fmax(1.0, fabs(sensor2_gsl[real(i)]));

		absolute_error = fabs(sensor2_gsl[imag(i)] - normalize_factor*unfix(*(sensor2[0]+imag(r_index))));
		average_abs_error2 += absolute_error;
		average_rel_error2 += absolute_error/fmax(1.0, fabs(sensor2_gsl[imag(i)]));
	}



	average_abs_error1 /= length/2;
	average_rel_error1 /= length/2;
	average_abs_error2 /= length/2;
	average_rel_error2 /= length/2;

	if(verbose){
		printf("bits for input: %d\n", total_bits);
		if(had_overflow) printf("there were %d overflows in multiplications", had_overflow);
		printf("average absolute error: %f and %f\n", average_abs_error1, average_abs_error2);
		printf("average relative error: %f and %f\n", average_rel_error1, average_rel_error2);
	}
	else
	{
		
		printf("%f %f %f %f\n", average_abs_error1,average_abs_error2,average_rel_error1,average_rel_error2);
	}
}

void run_default_mode(long * sensor1[], long * sensor2[], int number_of_bursts){
	double * output = malloc(sizeof(double)*length/2);
	for(int i = 0; i < number_of_bursts; i++){
		output[i] = 0.0;
	}

	double tmp1;
	double tmp2;
	int r_index;
	for(int burst = 0; burst < number_of_bursts; burst++){
		radix2_fft(sensor1[burst]);
		radix2_fft(sensor2[burst]);
		for(int i = 0; i < length/2; i++){
			r_index = lookup(i);
			tmp1 = unfix(sensor1[burst][real(r_index)]) * unfix(sensor1[burst][real(r_index)]) + unfix(sensor1[burst][imag(r_index)])*unfix(sensor1[burst][imag(r_index)]);
			tmp2 = unfix(sensor2[burst][real(r_index)]) * unfix(sensor2[burst][real(r_index)]) + unfix(sensor2[burst][imag(r_index)])*unfix(sensor2[burst][imag(r_index)]);


			output[i] += (tmp1)/number_of_bursts;
		}
	}
	output[2] = had_overflow * 10;
	for(int i = 0; i < length/2; i++){
		printf("%f ",output[i]);
	}
	
		   
}
