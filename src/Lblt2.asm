[org 0x08000]

[bits 32]
;THIS WONT WORK FOR MY ACTUAL KERNEL.
start:
    cli
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x7c000
    xor di, di
    xor ax, ax
    mov esi, 0xB8000
.clear:
    mov word [esi], ax
    add esi, 2
    inc di
    cmp di, 2000
    jl .clear
    mov ebx, mel      ; label address
    call print
    jmp dword 0x08:0x09000    ; Jump to loaded sector
    

print:
    mov esi, 0xB8000
    mov ah, 0x0F
    .print_loop:
        mov al, [ebx]
        test al, al
        je .done
        mov word [esi], ax
        add esi, 2
        inc ebx
        jmp .print_loop

    .done:
        ret

mel db 'Loading 32 bit kernel...', 0
times 1024 - ($ - $$) db 0