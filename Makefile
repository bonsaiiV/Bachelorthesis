dft: dft.o
	gcc dft.o -o dft -lm

dft.o: dft.c
	gcc -c dft.c -o dft.o

fft: fft.o
	gcc fft.o -o fft -lm
fft.o: fft.c mycomplex.h
	gcc -c fft.c -o fft.o
clean:
	rm -f *.o
	rm -f dft fft