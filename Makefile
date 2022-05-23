dft: dft.o
	gcc dft.o -o dft -lm

dft.o: dft.c
	gcc -c dft.c -o dft.o

fft: fft.o
	gcc fft.o -o fft -lm -lgsl -lgslcblas -Wl,-rpath=/usr/local/lib
fft.o: fft.c mycomplex.h
	gcc -c fft.c -o fft.o
fix_fft: fix_fft.o
	gcc fix_fft.o -o fix_fft -lm -lgsl -lgslcblas -Wl,-rpath=/usr/local/lib
fix_fft.o: fix_fft.c
	gcc -c fix_fft.c -o fix_fft.o
clean:
	rm -f *.o
	rm -f dft fft