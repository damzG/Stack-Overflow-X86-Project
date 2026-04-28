all: project2

project2: project2.o
	ld project2.o -o project2

project2.o: project2.asm
	nasm -f elf64 project2.asm -o project2.o

run: project2
	./project2

debug: project2
	gdb ./project2

clean:
	rm -f *.o project2