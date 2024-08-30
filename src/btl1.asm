[org  0x7C00]
clc

SegmentedReg:
    xor ax, ax 
    mov ds, ax
    mov ax, 0x7E00
    mov es, ax
    mov esp, 0x105000

lowermemcheck:
    clc
    xor ax, ax
    int 0x12
    cmp ax, 639 ;; ax contains the amount of RAM in kb, starting from 0, "640kb outta be enough for anybody"
    jne mem_error

DiskLoad:
    cld
    mov si, 0        ; Sector index
    mov dl, 0x80     ; Drive number (default hard disk)
    mov ah, 0x02     ; BIOS function: read sectors
    mov al, 8        ; Number of sectors to read
    mov ch, 0x00     ; Cylinder (0)
    mov dh, 0x00     ; Head (0)
    mov cl, 0x02     ; Sector (2)
    mov bx, 0x7E00   ; Memory location to read into
    int 0x13         ; BIOS interrupt

    jc disk_error    ; If carry flag is set, jump to disk_error

    ;; Jump to the second stage at 0x7E00
    jmp 0x7E00:0000  ; Note: CS=0x7E0, IP=0x0000

mem_error:
    mov ah, 0x0E  
    mov al, 'm'   
    int 0x10
    jmp $

disk_error:
    mov ah, 0x0E  
    mov al, 'd'   
    int 0x10
    jmp $

times 510-($-$$) db 0
db 0x55, 0xaa
