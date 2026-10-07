
huntkillasm: huntkillasm.c asm.o
	gcc -static huntkillasm.c asm.o -o huntkillasm

huntkillasm-debug: huntkillasm.c asm.o-debug
	gcc -static -g huntkillasm.c asm.o -o huntkillasm

huntkillc:
	gcc huntkillc.c -o huntkillc

huntkillc-debug:
	gcc -g huntkillc.c -o huntkillc

asm.o: asm.asm
	nasm asm.asm -f elf64 -l asm.lst -o asm.o

asm.o-debug: asm.asm
	nasm asm.asm -DDEBUG -f elf64 -l asm.lst -o asm.o

clean:
	rm -f *.o
	rm -f huntkillasm
	rm -f huntkillc
