gen_twiddle: bin/gen_twiddle
	:
bin/gen_twiddle: bin/gen_twiddle.o
	gcc bin/gen_twiddle.o -o bin/gen_twiddle -lm
bin/gen_twiddle.o: gen_twiddle.c 
	gcc -c -o bin/gen_twiddle.o gen_twiddle.c

gen_tb: bin/gen_tb
	:
bin/gen_tb: bin/gen_tb.o
	gcc bin/gen_tb.o -o bin/gen_tb
bin/gen_tb.o: gen_tb.c
	gcc -c -o bin/gen_tb.o gen_tb.c
