CC = gcc
CFLAGS = -Wall -Wextra -Werror

all: build run

build: main.c
	$(CC) $(CFLAGS) -o sys_calls main.c

run: sys_calls
	./sys_calls

clean:
	rm -f main
	rm -r SysDir
