[org 0x8000]

[bits 32]
start:
    cli
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x9FFF0        ; set up stack somewhere safe

    ; Clear the screen
    xor di, di
    xor ax, ax
    mov esi, 0xB8000
    .loop:  
        mov word [esi], ax
        add dword esi, 2
        inc di
        cmp di, 2000
        jge hang
        jl .loop

hang:
    mov byte [0xB8000], 'B'
    mov byte [0xB8001], 0x0F
    jmp $
times 1024 - ($ - $$) db 0
