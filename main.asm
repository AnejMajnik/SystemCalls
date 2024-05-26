section .data
    filePath db './SysDir', 0        ; Določi pot do imenika z zaključnim ničelnim znakom
    mode dd 0777o                    ; Določi način za ustvarjanje imenika (oktalen 0777)
    fileName db './PidTimeData.dat', 0 ; Določi ime datoteke z zaključnim ničelnim znakom
    mode_2 dd 0666o                  ; Določi način za ustvarjanje datoteke (oktalen 0666)
    mode_3 dd 0640o                  ; Določi način za spreminjanje dovoljenj za datoteko (oktalen 0640)
    format db 'PID: ', 0             ; Oblika niza za PID
    format2 db ', Time: ', 0         ; Oblika niza za čas

section .bss
    pid resd 1       ; Rezerviraj prostor za PID (4 bajti)
    raw_time resd 1  ; Rezerviraj prostor za surovi čas (4 bajti)
    fd resd 1        ; Rezerviraj prostor za deskriptor datoteke
    pid_str resb 12  ; Medpomnilnik za niz PID (12 bajtov je dovolj za 32-bitno celo število in zaključni ničelni znak)
    time_str resb 12 ; Medpomnilnik za niz časa (12 bajtov je dovolj za 32-bitno celo število in zaključni ničelni znak)
    output_str resb 50 ; Medpomnilnik za končni izhodni niz

section .text
global _start

_start:
    ; Ustvari imenik
    mov eax, 39         ; sistemski klic: mkdir
    mov ebx, filePath   ; prvi argument (filePath)
    mov ecx, dword [mode] ; drugi argument (mode)
    int 0x80            ; sistemski klic

    ; Spremeni imenik
    mov eax, 12         ; sistemski klic: chdir
    mov ebx, filePath   ; prvi argument (ime datoteke)
    int 0x80            ; sistemski klic

    ; Odpri datoteko
    mov eax, 5          ; sistemski klic: open
    mov ebx, fileName   ; prvi argument (ime datoteke)
    mov ecx, 0102o      ; drugi argument (zastavice) O_CREAT | O_WRONLY
    mov edx, dword [mode_2] ; tretji argument (mode)
    int 0x80            ; sistemski klic
    mov [fd], eax       ; shrani deskriptor datoteke za kasnejšo uporabo

    ; Spremeni dovoljenja za datoteko
    mov eax, 15         ; sistemski klic: chmod
    mov ebx, fileName   ; prvi argument (ime datoteke)
    mov ecx, dword [mode_3] ; drugi argument (mode) -rw-r-----
    int 0x80            ; sistemski klic

    ; Pridobi PID
    mov eax, 20         ; sistemski klic: getpid
    int 0x80            ; sistemski klic
    mov [pid], eax      ; shrani vrnjeno vrednost v pid

    ; Pretvori PID v niz
    mov eax, [pid]      ; naloži PID
    lea edi, [pid_str]  ; naloži naslov medpomnilnika za niz PID
    call itoa           ; pretvori PID v niz

    ; Pridobi trenutni čas
    mov eax, 13         ; sistemski klic: time
    xor ebx, ebx        ; ničelni kazalec = shrani čas
    int 0x80            ; sistemski klic
    mov [raw_time], eax ; shrani vrnjeno vrednost v raw_time

    ; Pretvori raw_time v niz
    mov eax, [raw_time] ; naloži raw_time
    lea edi, [time_str] ; naloži naslov medpomnilnika za niz časa
    call itoa           ; pretvori raw_time v niz

    ; Sestavi izhodni niz "PID: <pid>, Time: <time>"
    lea edi, [output_str]
    lea esi, [format]
    call strcpy
    lea esi, [pid_str]
    call strcat
    lea esi, [format2]
    call strcat
    lea esi, [time_str]
    call strcat

    ; Zapiši izhodni niz v datoteko
    mov eax, 4          ; sistemski klic: write
    mov ebx, [fd]       ; prvi argument (fd)
    lea ecx, [output_str] ; drugi argument (medpomnilnik)
    mov edx, 50         ; tretji argument (dolžina)
    int 0x80            ; sistemski klic

    ; Zapri datoteko
    mov eax, 6          ; sistemski klic: close
    mov ebx, [fd]       ; prvi argument (fd)
    int 0x80            ; sistemski klic

    ; Izhod iz programa
    mov eax, 1          ; sistemski klic: exit
    xor ebx, ebx        ; izhodna koda 0
    int 0x80            ; sistemski klic

itoa:
    ; Pretvori celo število v EAX v niz z zaključnim ničelnim znakom
    ; Vhod: EAX = celo število za pretvorbo
    ; Izhod: EDI = kazalec na niz z zaključnim ničelnim znakom

    ; Shrani registre
    push eax            ; shrani EAX na sklad
    push ecx            ; shrani ECX na sklad
    push edx            ; shrani EDX na sklad

    ; Inicializiraj števec
    xor ecx, ecx        ; počisti ECX (števec)

    ; Preveri, ali je EAX enak nič
    cmp eax, 0          ; primerjaj EAX z 0
    jnz .convert_loop   ; če ni nič, skoči v pretvorbeno zanko

    ; Poseben primer za ničlo
    mov byte [edi], '0' ; premakni '0' v medpomnilnik
    mov byte [edi + 1], 0 ; dodaj zaključni ničelni znak
    jmp .done           ; skoči na konec

    .convert_loop:
        ; Deli EAX z 10
        mov edx, 0      ; počisti EDX pred deljenjem
        mov ebx, 10     ; nastavi delitelj na 10
        div ebx         ; deli EAX z 10, rezultat v EAX, ostanek v EDX

        ; Shrani ostanek kot znak v medpomnilnik
        add dl, '0'     ; pretvori ostanek v ASCII
        mov [edi + ecx], dl ; shrani znak v medpomnilnik

        ; Povečaj števec
        inc ecx         ; povečaj števec

        ; Preveri, ali je količnik enak nič
        test eax, eax   ; preveri, ali je EAX enak nič
        jnz .convert_loop ; če ni nič, ponovi zanko

    ; Dodaj zaključni ničelni znak
    mov byte [edi + ecx], 0 ; dodaj zaključni ničelni znak

    ; Obrni niz v mestu
    xor ebx, ebx        ; počisti EBX (začetni indeks)
    dec ecx             ; zmanjša ECX (končni indeks)

    .reverse_loop:
        cmp ebx, ecx    ; primerjaj začetni in končni indeks
        jge .done       ; če je začetni >= končni, končaj obračanje

        ; Zamenjaj znake
        mov al, [edi + ebx] ; naloži znak na začetnem indeksu
        mov ah, [edi + ecx] ; naloži znak na končnem indeksu
        mov [edi + ebx], ah ; shrani končni znak na začetni indeks
        mov [edi + ecx], al ; shrani začetni znak na končni indeks

        ; Premakni indekse
        inc ebx         ; povečaj začetni indeks
        dec ecx         ; zmanjša končni indeks
        jmp .reverse_loop ; ponovi zanko

    .done:
        ; Obnovi registre
        pop edx         ; obnovi EDX s sklada
        pop ecx         ; obnovi ECX s sklada
        pop eax         ; obnovi EAX s sklada
        ret             ; vrni se iz itoa

strcpy:
    ; Kopira niz z zaključnim ničelnim znakom iz ESI v EDI
    ; Vhod: ESI = izvorni niz, EDI = ciljni medpomnilnik

    .copy_loop:
        lodsb           ; naloži bajt iz [ESI] v AL, in poveča ESI
        stosb           ; shrani bajt v AL v [EDI], in poveča EDI
        test al, al     ; preveri, ali je bajt v AL nič
        jnz .copy_loop  ; ponovi, dokler ni ničelni bajt
    ret                 ; vrni se iz strcpy

strcat:
    ; Združi niz z zaključnim ničelnim znakom iz ESI na konec EDI
    ; Vhod: ESI = izvorni niz, EDI = ciljni medpomnilnik

    ; Najdi konec ciljnega niza
    .find_end:
        lodsb           ; naloži bajt iz [ESI] v AL, in poveča ESI
        test al, al     ; preveri, ali je bajt v AL nič
        jz .concat      ; če je nič, je konec niza najden
        stosb           ; shrani bajt v AL v [EDI], in poveča EDI
        jmp .find_end   ; ponovi, dokler ni najden ničelni bajt

    ; Kopiraj izvorni niz na konec ciljnega niza
    .concat:
        lodsb           ; naloži bajt iz [ESI] v AL, in poveča ESI
        stosb           ; shrani bajt v AL v [EDI], in poveča EDI
        test al, al     ; preveri, ali je bajt v AL nič
        jnz .concat     ; ponovi, dokler ni najden ničelni bajt
    ret                 ; vrni se iz strcat
