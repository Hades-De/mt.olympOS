[bits 16]
[org 0x7C00]

start:
    cli 
    mov sp, 0x7F00 ; set the stack
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov [disk], dl 
    ;check lba
    clc
    mov ah, 0x41
    mov bx, 0x55aa
    mov dl, [disk]
    int 0x13
    jc no_support_lba
    cmp bx, 0xaa55
    jne no_support_lba
    and cx, 0x01
    cmp cx, 0x01
    jne no_support_lba
    ;setup dap
    mov byte [dap], 0x10 ;size of dap
    mov byte [dap+1], 0 ; always 0
    mov word [dap+2], 10 ;num sec
    mov word [dap+4], 0x0000 ; offset
    mov word [dap+6], 0x0900 ;seg
    mov word [dap+8], 1 ; lba num
    ;read from disk
    ;ds should be 0 but we xor it again
    clc;clear carry incase we somehow missed it
    xor ax, ax
    mov ds, ax
    mov si, dap
    mov ah, 0x42
    mov dl, [disk]
    int 0x13
    jc no_support_lba
    cmp ah, 0x00
    jne fail_lba
    mov ax, [disk]
    push ax
    jmp 0x0900:0x0000

    fail_lba:
        mov al, ah
        add al, '0'
        mov ah, 0xe
        int 0x10
        mov cx, 0x1f
        jmp wait_loop
    no_support_lba:
        mov ah, 0xe
        mov al, 'L'
        int 0x10
        mov cx, 0x1f
        wait_loop:
            mov ah, 0x86
            int 0x15
            loop wait_loop
            int 0x18

disk db 0x00
dap:
    times 16 db 0
times 510 - ($ - $$) db 0
dw 0xAA55