#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>

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
        "syscall\n" // execute system call
        "movq %%rax, %0\n" // shrani return value
        : "=r" (result) // shrani output v result
        : "r" (dirPath) // poda input za path
        : "rax", "rdi" // spremenjeni registri
    );

    if (result == 0) {
        printf("Successfully changed working directory to %s\n", dirPath);
    } else {
        printf("Error changing directory: %s\n", strerror(errno));
        return 1; // izhod če klic spodleti
    }

    const char* fileName = "./PidTimeData.dat";
    mode = 0666;
    int flags = O_CREAT | O_WRONLY;
    int fd;

    // ustvarjanje datoteke PidTimeData.dat
    asm volatile (
        "movq $2, %%rax\n" // load system call number za open (2) v rax
        "movq %1, %%rdi\n" // load prvi argument klica open (path)
        "movq %2, %%rsi\n" // load drugi argument klica open (flags)
        "movq %3, %%rdx\n" // load tretji argument klica open (mode)
        "syscall\n"
        "movq %%rax, %0\n" // shrani return value
        : "=r" (result)
        : "r" (fileName), "r" ((long)flags), "r" ((long)mode) // input path, flags in mode
        : "rax", "rdi", "rsi", "rdx" // spremenjeni registri
    );

    fd = result;

    if (result >= 0) {
        printf("File successfully created with file descriptor %ld\n", result);
    } else {
        printf("Error creating file: %s\n", strerror(errno));
        return 1; // Exit if file creation fails
    }

    mode = 0640;

    // spremeni pravice na -rw-r-----
    asm volatile (
        "movq $90, %%rax\n" // load system call number za chmod (90)
        "movq %1, %%rdi\n" // load prvi argument klica chmod (path)
        "movq %2, %%rsi\n" // load drugi argument klica chmod (mode)
        "syscall\n"
        "movq %%rax, %0\n" // shrani return value
        : "=r" (result)
        : "r" (fileName), "r" ((long)mode)
        : "rax", "rdi", "rsi"
    );

    if (result == 0) {
        printf("File permissions successfully changed to %o\n", mode);
    } else {
        printf("Error changing file permissions: %s\n", strerror(errno));
        return 1; // Exit if changing permissions fails
    }

    pid_t pid;

    // pridobi PID
    asm volatile (
        "movq $39, %%rax\n" // load system call number za getpid (39)
        "syscall\n"
        "mov %%eax, %0\n"   // shrani return vrednost (pid) iz eax v pid spremenljivko
        : "=r" (pid)
        :
        : "rax"
    );

    printf("PID: %d\n", pid);

    time_t rawtime;

    // pridobi time
    asm volatile (
        "movq $201, %%rax\n" // load system call number za time (201)
        "xor %%rdi, %%rdi\n" // podaj null pointer kot argument
        "syscall\n"
        "movq %%rax, %0\n"
        : "=r" (rawtime)
        :
        : "rax", "rdi"
    );

    struct tm * timeinfo;
    timeinfo = localtime(&rawtime);
    char buffer[80];
    strftime(buffer, 80, "%d.%m.%Y %H:%M", timeinfo);

    // print datum in čas
    printf("Current time: %s\n", buffer);

    // priprava za pisanje
    char writeBuffer[160];
    snprintf(writeBuffer, sizeof(writeBuffer), "PID: %d, Time: %s\n", pid, buffer);

    ssize_t bytes_written;

    // pisanje v datoteko
    asm volatile (
        "movq $1, %%rax\n" // load system call number za write (1)
        "movq %1, %%rdi\n" // load prvi argument klica write (file descriptor)
        "movq %2, %%rsi\n" // load drugi argument klica open (buffer)
        "movq %3, %%rdx\n" // load tretji argument klica open (length)
        "syscall\n"
        "movq %%rax, %0\n"
        : "=r" (bytes_written)
        : "r" ((long)fd), "r" (writeBuffer), "r" ((long)strlen(writeBuffer))
        : "rax", "rdi", "rsi", "rdx"
    );

    if (bytes_written >= 0) {
        printf("Successfully wrote %zd bytes to the file\n", bytes_written);
    } else {
        printf("Error writing to file: %s\n", strerror(errno));
    }

    close(fd); // Close the file descriptor

    return 0;
}
