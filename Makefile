
hk: main.c asm.o
	gcc -static main.c asm.o -o hk

asm.o: asm.asm
	nasm asm.asm -f elf64 -l asm.lst -o asm.o

debug: asm.asm
	nasm asm.asm -DDEBUG -f elf64 -l asm.lst -o asm.o
clean:
	rm *.o
	rm hk
