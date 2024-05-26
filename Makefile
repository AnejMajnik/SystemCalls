CC = gcc
CFLAGS = -Wall -Wextra -Werror -m32

all: build_c run_c build_asm run_asm

build_c: main.c
	$(CC) $(CFLAGS) -o sys_calls_c main.c

run_c: sys_calls_c
	./sys_calls_c

build_asm: main.asm
	nasm -f elf32 -g -o main.o main.asm
	ld -m elf_i386 -g -o sys_calls_asm main.o

run_asm: sys_calls_asm
	./sys_calls_asm

clean:
	rm -f main
	rm -f -r SysDir
	rm -f sys_calls_c
	rm -f sys_calls
	rm -f main.o
	rm -f sys_calls_asm
	rm -f main_asm.o
