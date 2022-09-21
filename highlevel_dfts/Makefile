bin/fix_fft: bin/fix_fft.o
	gcc bin/fix_fft.o -o bin/fix_fft -lm -lgsl -lgslcblas -Wl,-rpath=/usr/local/lib
bin/fix_fft.o: fix_fft.c
	gcc -c fix_fft.c -o bin/fix_fft.o
clean:
	rm -f bin/*.o
	rm -f bin/fft
