.PHONY : clean

regen: grom.vhdl fft_tb.vhdl
	:

grom.vhdl: bin/gen_twiddle input/twid_config
	bin/gen_twiddle -c input/twid_config -o grom.vhdl
fft_tb.vhdl: bin/gen_tb input/tb_config
	bin/gen_tb -c input/tb_config -i input/Test.dat -o fft_tb.vhdl

gen_twiddle: bin/gen_twiddle
	:
bin/gen_twiddle: bin/gen_twiddle.o bin/common.o
	clang bin/gen_twiddle.o bin/common.o -o bin/gen_twiddle -lm
bin/gen_twiddle.o: src/gen_twiddle.c
	clang -c -o bin/gen_twiddle.o src/gen_twiddle.c

gen_tb: bin/gen_tb
	:
bin/gen_tb: bin/gen_tb.o bin/common.o
	gcc bin/gen_tb.o bin/common.o -o bin/gen_tb
bin/gen_tb.o: src/gen_tb.c
	gcc -c -o bin/gen_tb.o src/gen_tb.c

bin/common.o: src/common.c
	gcc -c -o bin/common.o src/common.c
clean:
	rm bin/*
