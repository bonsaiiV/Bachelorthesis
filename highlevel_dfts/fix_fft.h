#ifndef FIX_FFT
#define FIX_FFT

struct fftConfig{
	int n;
	int twiddle_bits;
	int do_round;
	int total_bits;
	int threads;
};

int run_fix_fft(long * x, struct fftConfig config);

float unfix(long a, int komma_pos);

long ifix(int a, int komma_pos);
long ffix(double a, int komma_pos);

int lookup(int index, int n);

#define real(...) __VA_ARGS__ * 2
#define imag(...) __VA_ARGS__ * 2 + 1

#endif
