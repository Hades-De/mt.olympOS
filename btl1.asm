[org  0x7C00]
clc

SegmentedReg:
    mov ax, 0x0000
    mov ds, ax
    mov ax, 0x7E00
    mov es, ax



DiskLoad:
    cld
    mov dl, 0x80    
    mov ah, 0x02
    mov al, 8
    mov ch, 0x00
    mov dh, 0x00
    mov cl, 0x02
    mov bx, 0x7E00
    int 0x13
    jc DiskLoad
    jnc 0x7E00

times 510-($-$$) db 0
db 0x55, 0xaa