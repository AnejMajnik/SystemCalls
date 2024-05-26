section .data
    filePath db './SysDir', 0
    mode dd 0777o
    fileName db './PidTimeData.dat', 0
    mode_2 dd 0666o
    mode_3 dd 0640o


section .bss
    pid resd 1      ;rezerviram prostor za PID (4 byte)
    raw_time resd 1     ;rezerviram prostor za time (4 byte)
    fd resd 1       ;prostor za file descriptor



section .text
global _start

_start:
    mov eax, 39     ;nalaganje mkdir (39)
    mov ebx, filePath   ;prvi argument (filePath)
    mov ecx, dword [mode]   ;drugi argument (mode)
    int 0x80    ;klic jedra

    mov eax, 12     ;nalaganje chdir (12)
    mov ebx, filePath       ;prvi argument (filename)
    int 0x80        ;klic jedra

    mov eax, 5      ;nalaganje open (5)
    mov ebx, fileName       ;prvi argument (filename)
    mov ecx, 0102o      ;drugi argument (flags) O_CREAT | O_WRONLY
    mov edx, dword [mode_2]     ;tretji argument (mode)
    int 0x80        ;klic jedra
    mov [fd], eax       ;shranim file descriptor, da lahko uporabim kasneje

    mov eax, 15     ;nalaganje chmod (15)
    mov ebx, fileName       ;prvi argument (filename)
    mov ecx, dword [mode_3]     ;drugi argument (mode) -rw-r-----
    int 0x80        ;klic jedra

    mov eax, 20     ;nalaganje getpid (20)
    int 0x80        ;klic jedra
    mov [pid], eax      ;shrani return value v pid

    mov eax, 13     ;nalaganje time (13)
    xor ebx, ebx        ;null pointer = store time
    int 0x80        ;klic jedra
    mov [raw_time], eax         ;shrani return value v raw_time

    mov eax, 4          ;nalaganje write (4)
    mov ebx, [fd]       ;prvi argument (fd)
    mov ecx, pid        ;drugi argument (buffer)
    mov edx, 4      ;tretji argument (length) v bytes
    int 0x80        ;klic jedra

    mov eax, 4          ;nalaganje write (4)
    mov ebx, [fd]       ;prvi argument (fd)
    mov ecx, raw_time        ;drugi argument (buffer)
    mov edx, 4      ;tretji argument (length) v bytes
    int 0x80        ;klic jedra

    mov eax, 6      ;nalaganje close (6)
    mov ebx, [fd]       ;prvi argument (fd)
    int 0x80        ;klic jedra


    mov eax, 1      ;sys_exit
    xor ebx, ebx    ;exit code 0
    int 0x80        ;klic jedra