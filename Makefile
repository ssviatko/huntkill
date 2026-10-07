
hk: main.c asm.o
	gcc -static -g main.c asm.o -o hk
	gcc -g huntkill.c -o huntkill

asm.o: asm.asm
	nasm asm.asm -f elf64 -l asm.lst -o asm.o

debug: asm.asm
	nasm asm.asm -DDEBUG -f elf64 -l asm.lst -o asm.o

clean:
	rm *.o
	rm hk
