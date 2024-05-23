#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

int main(){
    const char* dirPath = "./SysDir"; //pot do imenika
    int mode = 0777;

    long result;

    // ustvarjanje direktorija SysDir
    asm volatile (
        "movq $83, %%rax\n" // load system call number za mkdir (83) v rax register
        "movq %1, %%rdi\n" // load prvi argument klica mkdir (path) v rdi register
        "movq %2, %%rsi\n" // load drugi argument klica mkdir (mode) v rsi register
        "syscall\n" // execute system call
        "movq %%rax, %0\n" // shrani return value
        : "=r" (result) // shrani output v result spremenljivko
        : "r" (dirPath), "r" ((long)mode) // poda input za path in mode
        : "rax", "rdi", "rsi" // te registre assembly spremeni
    );

    if(result == 0){
        printf("Directory successfully created\n");
    } else {
        printf("Error creating directory: %s\n", strerror(errno));
    }

    // premik delovnega imenika v SysDir
    asm volatile (
        "movq $80, %%rax\n" // load system call number za chdir (80) v rax register
        "movq %1, %%rdi\n" // load argument klica chdir (path) v rdi register
    );

    return 0;
}
