regen: grom.vhdl fft_tb.vhdl
	:
grom.vhdl: bin/gen_twiddle twid_config
	bin/gen_twiddle -c twid_config -o grom.vhdl
fft_tb.vhdl: bin/gen_tb tb_config
	bin/gen_tb -c tb_config -i Test.dat -o fft_tb.vhdl

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
clean:
	rm bin/*
