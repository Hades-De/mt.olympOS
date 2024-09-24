[org  0x7C00]
clc

SegmentedReg:
    xor ax, ax 
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov ax, 0x7E00
    mov es, ax
    mov esp, 0x105000

lowermemcheck:
    clc
    xor ax, ax
    int 0x12
    cmp ax, 639 ;; ax contains the amount of RAM in kb, starting from 0, "640kb outta be enough for anybody"
    jne mem_error
clc

stacetc:
    mov cx, 30412          ; CX = 30,412 bytes AKA 29.75 KiB 

;;maybe make another 2nd part for 16 bit kernel operations if the user has less than 640kb of RAM
highmemchk:
    prechk:
        xor dx, dx
        xor ax, ax
        xor di, di
        mov es, ax
        mov di, 0x0500
        cmp di, 0x0500
        jne prechk
    ;;es:di = 0x00000500
    int15820:
        clc
        xor ebx, ebx
        xor eax, eax
        mov edx, 0x534D4150
        mov eax, 0xE820
        mov ecx, 24
        int 0x15
    pastcheck:
        jc done
        cmp eax, 0x534D4150
        jne mem_error_eax
        cmp ebx, 0 
        je done
        clc
        movzx dx, cl        ; Zero-extend CL into DX (DX = 0000:CL)
        sub cx, dx          ; Subtract DX from CX
        jc buffer_full      ; Jump if there's a carry, meaning the buffer is too small
        clc
            CLchk:
                cmp cl, 0x20 ;32 byte
                je validmem
                cmp cl, 0x14 ;20 byte
                je validmem
                cmp cl, 0x18 ;24 byte
                je validmem
                jmp validmem

            validmem:
                add di, dx
                mov edx, 0x534D4150
                mov eax, 0xE820
                mov ecx, 24
                int 0x15
                jmp pastcheck

            buffer_full:
                mov ah, 0x0E
                mov bx, MBF
                jmp print_string_SRT
            
            done: ;;it seems that i cant "mov al, [bx]"
                clc
                mov ah, 0x0E
                mov bx, HMD
                jmp print_string_SRT

print_string_SRT:
    mov al, [bx]
    cmp al, 0
    je end
    mov ah, 0x0E
    int 0x10
    inc bx
    jmp print_string_SRT

mem_error_eax: 
    mov ah, 0x0E
    mov bx, MEE
    jmp print_string_SRT

end:
    mov ah, 0x0E  
    mov al, 's'  
    int 0x10
    jmp $

DEE db "invalid disk inserted",0
MEL db "lower memory error",0
MEE db "upper memory check failed EAX", 0
MBF db "memory buffer is full",0
HMD db "higher memory reading done", 0
DiskLoad16b:
    ;something to boot the 16bit Kernel and shoud make it so that it jumps to mem error if less than 100kb of ram cuz i aint messing with that (yet :troll:)

;;DiskLoadN16b: ;; fix it aint loading shit, main problem, 0x7E00 is empty, my second stage should be there, but isn't?
  ;;  cld
    ;;mov si, 0        ; Sector index
   
mem_error:
    mov ah, 0x0E
    mov bx, MEL
    jmp print_string_SRT

disk_error:
    mov ah, 0x0E
    mov bx, DEE
    jmp print_string_SRT

times 510-($-$$) db 0
db 0x55, 0xaa
