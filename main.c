#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>

int main() {
    const char* dirPath = "./SysDir"; // path to directory
    int mode = 0777;
    int result;

    // create directory SysDir
    asm volatile (
        "movl $39, %%eax\n" // load system call number for mkdir (39) into eax register
        "movl %1, %%ebx\n" // load first argument of mkdir (path) into ebx register
        "movl %2, %%ecx\n" // load second argument of mkdir (mode) into ecx register
        "int $0x80\n" // trigger system call
        "movl %%eax, %0\n" // save return value
        : "=r" (result) // save output in result variable
        : "g" (dirPath), "g" (mode) // provide input for path and mode
        : "eax", "ebx", "ecx" // these registers are modified by assembly
    );

    if (result == -1) {
        printf("Error creating directory: %s\n", strerror(errno));
    } else {
        printf("Directory successfully created\n");
    }

    // change working directory to SysDir
    asm volatile (
        "movl $12, %%eax\n" // load system call number for chdir (12) into eax register
        "movl %1, %%ebx\n" // load argument of chdir (path) into ebx register
        "int $0x80\n" // trigger system call
        "movl %%eax, %0\n" // save return value
        : "=r" (result) // save output in result variable
        : "g" (dirPath) // provide input for path
        : "eax", "ebx" // these registers are modified by assembly
    );

    if (result == -1) {
        printf("Error changing directory: %s\n", strerror(errno));
        return 1; // exit if call fails
    } else {
        printf("Successfully changed working directory to %s\n", dirPath);
    }

    const char* fileName = "./PidTimeData.dat";
    mode = 0666;
    int flags = O_CREAT | O_WRONLY;
    int fd;

    // create file PidTimeData.dat
    asm volatile (
        "movl $5, %%eax\n" // load system call number for open (5) into eax
        "movl %1, %%ebx\n" // load first argument of open (path) into ebx
        "movl %2, %%ecx\n" // load second argument of open (flags) into ecx
        "movl %3, %%edx\n" // load third argument of open (mode) into edx
        "int $0x80\n"
        "movl %%eax, %0\n" // save return value
        : "=r" (fd)
        : "g" (fileName), "g" (flags), "g" (mode) // input path, flags and mode
        : "eax", "ebx", "ecx", "edx" // these registers are modified by assembly
    );

    if (fd == -1) {
        printf("Error creating file: %s\n", strerror(errno));
        return 1; // Exit if file creation fails
    } else {
        printf("File successfully created with file descriptor %d\n", fd);
    }

    mode = 0640;

    // change file permissions to -rw-r-----
    asm volatile (
        "movl $15, %%eax\n" // load system call number for chmod (15) into eax
        "movl %1, %%ebx\n" // load first argument of chmod (path) into ebx
        "movl %2, %%ecx\n" // load second argument of chmod (mode) into ecx
        "int $0x80\n"
        "movl %%eax, %0\n" // save return value
        : "=r" (result)
        : "g" (fileName), "g" (mode)
        : "eax", "ebx", "ecx"
    );

    if (result == -1) {
        printf("Error changing file permissions: %s\n", strerror(errno));
        return 1; // Exit if changing permissions fails
    } else {
        printf("File permissions successfully changed to %o\n", mode);
    }

    int pid;

    // get PID
    asm volatile (
        "movl $20, %%eax\n" // load system call number for getpid (20) into eax
        "int $0x80\n"
        "movl %%eax, %0\n"   // save return value (pid) from eax to pid variable
        : "=r" (pid)
        :
        : "eax"
    );

    printf("PID: %d\n", pid);

    time_t rawtime;

    // get time
    asm volatile (
        "movl $13, %%eax\n" // load system call number for time (13) into eax
        "xorl %%ebx, %%ebx\n" // provide null pointer as argument
        "int $0x80\n"
        "movl %%eax, %0\n"
        : "=r" (rawtime)
        :
        : "eax", "ebx"
    );

    struct tm * timeinfo;
    timeinfo = localtime(&rawtime);
    char buffer[80];
    strftime(buffer, 80, "%d.%m.%Y %H:%M", timeinfo);

    // print date and time
    printf("Current time: %s\n", buffer);

    // prepare for writing
    char writeBuffer[160];
    snprintf(writeBuffer, sizeof(writeBuffer), "PID: %d, Time: %s\n", pid, buffer);

    ssize_t bytes_written;

    // write to file
    asm volatile (
        "movl $4, %%eax\n" // load system call number for write (4) into eax
        "movl %1, %%ebx\n" // load first argument of write (file descriptor) into ebx
        "movl %2, %%ecx\n" // load second argument of write (buffer) into ecx
        "movl %3, %%edx\n" // load third argument of write (length) into edx
        "int $0x80\n"
        "movl %%eax, %0\n"
        : "=r" (bytes_written)
        : "g" (fd), "g" (writeBuffer), "g" ((int)strlen(writeBuffer))
        : "eax", "ebx", "ecx", "edx"
    );

    if (bytes_written == -1) {
        printf("Error writing to file: %s\n", strerror(errno));
    } else {
        printf("Successfully wrote %zd bytes to the file\n", bytes_written);
    }

    close(fd); // Close the file descriptor

    return 0;
}
