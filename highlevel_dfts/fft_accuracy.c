#include <stdio.h>
#include <stdlib.h>
#include <gsl/gsl_fft_complex.h>
#include <unistd.h>
#include <getopt.h>

#include "fix_fft.h"

#define print_e(args...) fprintf(stderr, args)

int komma_pos = 0;            

int length;

int error_mode = 0;

int verbose = 0;


void read_input (const char* file_name, int number_of_bursts, long *(*sensor1_ptr)[], long *(*sensor2_ptr)[])
{
    long **sensor1 = *sensor1_ptr;
    long **sensor2 = *sensor2_ptr;
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
            *(sensor1[burst]+real(i)) = ifix(read1, komma_pos);
            *(sensor1[burst]+imag(i)) = 0;
            *(sensor2[burst]+real(i)) = ifix(read2, komma_pos);
            *(sensor2[burst]+imag(i)) = 0;
        }
    }
    fclose(numbers);
}


long create_input(int length, int i){
    int F = 5;
    return ffix(sin(M_PI * i/(length/F))+ cos(M_PI * i/(length/(F-1))), komma_pos);
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
    "    default : 1\n"
    "  -t: takes 1 positional integer argument, which specifies the width in bits of the twiddle factor.\n"
    "    default : 32\n"
    "  -e: takes no argument. Enables error mode, comparison to gsl library fft.\n"
    "  -p: takes no argument. Enables printing of FFT result. Recomended only with low amount of input for the FFT\n"
    "  -l: takes 1 positional integer argument, which specifies the length of one burst as 2^l.\n"
    "  default : 15\n\n"
    "Any argument is neither starting with \"-\" nor consumed as argument for another option, is considered the input file.\n"
    " If there are multiple input files only the last one is used.\n";

void run_print_mode(long * sensor1[], struct fftConfig fft_config);
void run_error_mode(long * sensor1[], long * sensor2[], struct fftConfig fft_config);
void run_default_mode(long * sensor1[], long * sensor2[], int number_of_bursts, struct fftConfig fft_config);
int main(int argc, char *argv[]){
    int number_of_bursts = 1;
    int print_mode = 0;
    int print_help = 0;
	struct fftConfig fft_config;
	fft_config.twiddle_bits = 32;
	fft_config.threads = 1;
	fft_config.do_round = 0;
	fft_config.n = 15;
	fft_config.total_bits = 32;
	// get options provided via commandline
	struct option longopts[] = {
		{"help", 0, 0, 'h'},
		{"length", 1, 0, 'l'},
		{"bits", 1, 0, 'b'},
		{"bursts", 1, 0, 'n'},
		{"twiddle", 1, 0, 't'},
		{"threads", 1, 0, 'm'},
		{0,0,0,0}};
	char * shortopts = "h?n:b:l:evpt:m:";

	int opt;
    while ((opt = getopt_long(argc, argv, shortopts, longopts, 0)) != -1){
		switch(opt){
			case 'h':
				print_help = 1;
				break;
			case 'v':
				verbose = 1;
				break;
			case 'n':
				get_int(&number_of_bursts, optarg, opt);
				break;
			case 'b':
				get_int(&fft_config.total_bits, optarg, opt);
				break;
			case 'l':
				get_int(&fft_config.n, optarg, opt);
				break;
			case 't':
				get_int(&fft_config.twiddle_bits, optarg, opt);
				break;
			case 'm':
#ifdef MULTI_THREAD
				get_int(&fft_config.threads, optarg, opt);
#else
				fprintf(stderr, "Not compiled with support for multithreading.\n");
				exit(1);
#endif
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
	if(fft_config.twiddle_bits < 3){
		print_e("twiddle needs at least 3 bits");
		exit(EXIT_FAILURE);
	}
    if(error_mode && (number_of_bursts != 1)){
        if(verbose) fprintf(stderr, "In error_mode number of bursts need to be 1.\nDefaulting number of bursts to 1.\n");
        number_of_bursts = 1;
    }
    komma_pos = fft_config.total_bits - 13;

    length = 1 << fft_config.n;
    long * sensor1[number_of_bursts];
    long * sensor2[number_of_bursts];
    for(int i = 0; i < number_of_bursts; i++){
        sensor1[i] = malloc(sizeof(long)*2*length);
        sensor2[i] = malloc(sizeof(long)*2*length);
    }

    
    long * (*sensor1_ptr)[] = &sensor1;
    long * (*sensor2_ptr)[] = &sensor2;

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
		run_print_mode(sensor1, fft_config);
    }
    else if(error_mode){
		run_error_mode(sensor1, sensor2, fft_config);
    }else
    {
		run_default_mode(sensor1, sensor2, number_of_bursts, fft_config);
	}
    for(int i = 0; i < number_of_bursts; i++){
		free(sensor1[i]);
		free(sensor2[i]);
    }
}

void run_print_mode(long * sensor1[], struct fftConfig fft_config) {
	printf("entering print mode\n");
	for(int i = 0; i< length; i++){
		printf("%f + %fi ,",
			unfix(*(sensor1[0]+real(i)), komma_pos),
			unfix(*(sensor1[0]+imag(i)), komma_pos)
		);
	}
	printf("\n");

	run_fix_fft(sensor1[0], fft_config);
	for(int i = 0; i< length; i++){
		int ri = lookup(i, fft_config.n);
		printf("%f + %fi ,",
			unfix(*(sensor1[0]+real(ri)), komma_pos),
			unfix(*(sensor1[0]+imag(ri)), komma_pos)
		);
	}
	printf("\n");
}

void run_error_mode(long * sensor1[], long * sensor2[], struct fftConfig fft_config){
	int had_overflow = 0;
	// setup gsl input
	double * sensor1_gsl;
	double * sensor2_gsl;
	sensor1_gsl = malloc(sizeof(double)*2*length);
	sensor2_gsl = malloc(sizeof(double)*2*length);
	for(int i = 0; i < length; i++){
		sensor1_gsl[real(i)] = unfix(sensor1[0][real(i)], komma_pos);
		sensor1_gsl[imag(i)] = unfix(sensor1[0][imag(i)], komma_pos);
		sensor2_gsl[real(i)] = unfix(sensor2[0][real(i)], komma_pos);
		sensor2_gsl[imag(i)] = unfix(sensor2[0][imag(i)], komma_pos);
	}

	// calculate both ffts
	gsl_fft_complex_radix2_forward(sensor1_gsl, 1,length);
	gsl_fft_complex_radix2_forward(sensor2_gsl, 1,length);

	had_overflow += run_fix_fft(sensor1[0], fft_config);
	had_overflow += run_fix_fft(sensor2[0], fft_config);

/*
	for(int i = 0; i < length; i++){
		printf("sensor1: %f,\tsensor1-gsl: %f\n",
			unfix(sensor1[0][real(i)], komma_pos),
			sensor1_gsl[real(i)]
		);
	}//*/
	// calculate error
	float average_abs_error1 = 0.0;
	float average_rel_error1 = 0.0;
	float average_abs_error2 = 0.0;
	float average_rel_error2 = 0.0;
	float absolute_error;
	
	int r_index;
	int normalize_factor = (1 << fft_config.n);

	for(int i = 0; i < length/2; i++){
		r_index = lookup(i, fft_config.n);
		absolute_error = fabs(
			sensor1_gsl[real(i)] -
			normalize_factor *
				unfix(*(sensor1[0]+real(r_index)), komma_pos)
		);
		average_abs_error1 += absolute_error;
		average_rel_error1 += absolute_error/fmax(1.0, fabs(sensor1_gsl[real(i)]));

		absolute_error = fabs(
			sensor1_gsl[imag(i)] -
			normalize_factor *
				unfix(*(sensor1[0]+imag(r_index)), komma_pos)
		);
		average_abs_error1 += absolute_error;
		average_rel_error1 += absolute_error/fmax(1.0, fabs(sensor1_gsl[imag(i)]));

		absolute_error = fabs(
			sensor2_gsl[real(i)] -
			normalize_factor *
				unfix(*(sensor2[0]+real(r_index)), komma_pos)
		);
		average_abs_error2 += absolute_error;
		average_rel_error2 += absolute_error/fmax(1.0, fabs(sensor2_gsl[real(i)]));

		absolute_error = fabs(
			sensor2_gsl[imag(i)] -
			normalize_factor *
				unfix(*(sensor2[0]+imag(r_index)), komma_pos)
		);
		average_abs_error2 += absolute_error;
		average_rel_error2 += absolute_error/fmax(1.0, fabs(sensor2_gsl[imag(i)]));
	}

	free(sensor1_gsl);
	free(sensor2_gsl);


	average_abs_error1 /= length/2;
	average_rel_error1 /= length/2;
	average_abs_error2 /= length/2;
	average_rel_error2 /= length/2;

	if(verbose){
		printf("bits for input: %d\n", fft_config.total_bits);
		printf("there were %d overflows in multiplications\n", had_overflow);
		printf("average absolute error: %f and %f\n", average_abs_error1, average_abs_error2);
		printf("average relative error: %f and %f\n", average_rel_error1, average_rel_error2);
	}
	else
	{
		
		printf("%f %f %f %f\n", average_abs_error1,average_abs_error2,average_rel_error1,average_rel_error2);
	}
}

void run_default_mode(long * sensor1[], long * sensor2[], int number_of_bursts, struct fftConfig fft_config){
	double * output = malloc(sizeof(double)*length/2);
	for(int i = 0; i < length/2; i++){
		output[i] = 0.0;
	}
	int had_overflow = 0;

	double tmp1;
	int r_index;
	for(int burst = 0; burst < number_of_bursts; burst++){
		had_overflow += run_fix_fft(sensor1[burst], fft_config);
		run_fix_fft(sensor2[burst], fft_config);
		for(int i = 0; i < length/2; i++){
			r_index = lookup(i, fft_config.n);
			tmp1 = unfix(sensor1[burst][real(r_index)], komma_pos) *
				unfix(sensor1[burst][real(r_index)], komma_pos) +
				unfix(sensor1[burst][imag(r_index)], komma_pos) *
				unfix(sensor1[burst][imag(r_index)], komma_pos);


			output[i] += (tmp1)/number_of_bursts;
		}
	}
	output[2] = had_overflow * 10;
	for(int i = 0; i < length/2; i++){
		printf("%f ",output[i]);
	}
	free(output);
		   
}
