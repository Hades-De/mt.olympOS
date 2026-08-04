[org 0x9000]
[bits 16]
;msg so we know we made it to stage 2
    pop ax
    mov byte [disk], al
    mov ah, 0xe
    mov al, 'W'
    int 0x10
A20_test:
    ;query support
    mov ax, 0x2403
    int 0x15
    jc a20_ns
    test ah, ah
    jnz a20_ns
    ;get status
    clc
    ;if its here then its not active
    mov ax, 0x2401
    int 0x15
    jc a20_nac
    test ah, ah
    jnz a20_nac
    jmp a20_active
    a20_active:
        xor ax, ax
        mov es, ax
        mov di, 0x8000
        xor ebx, ebx
        mov edx, 0x534D4150
        xor eax, eax
        mov ax, 0xE820 ; since upper 16 bits should be 0
        mov ecx, 24
        int 0x15
        jc int_15_err
        cmp eax, 0x534D4150
        jne int_15_err
        .loop:
            ;pads the last 8 bytes with 0 to make it 32 byte entries
            mov si, di
            add si, 24
            mov dword [es:si], 0x00
            mov dword [es:si+4], 0x00
            add di, 32
            xor eax, eax
            mov ax, 0xe820
            mov edx, 0x534D4150
            mov ecx, 24
            int 0x15
            jc int_15_err
            cmp eax, 0x534D4150
            jne int_15_err
            test ebx, ebx
            jnz .loop
            mov ah, 0xe
            mov al, 'E'
            int 0x10
    gdt_setup:
        cli
        lgdt [gdt_descriptor]
        mov eax, cr0
        or eax, 1
        mov cr0, eax ;enable 32 bits
        jmp dword 0x08:ata_load   ; Jump to kernel

        gdt_start:
        dq 0x0000000000000000        ; null descriptor
        dq 0x00cf9a000000ffff        ; code segment: base=0, limit=4GB, flags=0x9A, gran=1
        dq 0x00cf92000000ffff        ; data segment: base=0, limit=4GB, flags=0x92, gran=1
    gdt_end:

    gdt_descriptor:
        dw gdt_end - gdt_start - 1
        dd gdt_start

[bits 32]
ata_load:
    cli
    mov ax, 0x10
    mov eax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x7c000
    mov esi, 0xb8000
    mov eax, 1
    mov byte [esi], 'a'
    mov byte [esi+1], 0x0f
            xor edx, edx
            mov dx, 0x3F6
            mov al, 0x04
            out dx, al
            in al, dx
            in al, dx
            in al, dx
            in al, dx
            mov al, 0x00
            out dx, al
            .wit:
                mov dx,0x1F7
                in al,dx
                test al,0x80
                jnz .wit
    .ata_setup:
            mov eax, lba_addr
            and eax, 0xff
            mov byte [lba_low], al
            mov eax, lba_addr
            shr eax, 8
            and eax, 0xff
            mov byte [lba_mid], al
            mov eax, lba_addr
            shr eax, 16
            and eax, 0xff
            mov byte [lba_high], al
            mov eax, lba_addr
            shr eax, 24
            and eax, 0x0f
            mov byte [lba_dr_hd], al
        mov al, [lba_dr_hd]
        or al, 0xE0
        mov dx, base_io_prim+6
        out dx, al 
        mov al, sectorcnt
        mov dx, base_io_prim+2
        out dx, al
        mov al, [lba_low]
        inc dx ;0x1f3
        out dx, al
        mov al, [lba_mid]
        inc dx;0x1f4
        out dx, al
        mov al, [lba_high]
        inc dx ;0x1f5
        out dx, al
        inc dx ;0x1f6
        inc dx ;0x1f7
        mov byte [esi], 'B'
        mov byte [esi+1], 0x0f
        .wait:
            in al, dx
            and al, 0xC0
            cmp al, 0x40
            jne .wait
        mov al, 0x20
        out dx, al
        mov ecx, 0x1f
        .wait_loop:
            jmp $+2
            loop .wait_loop
        mov byte [esi], 'D'
        mov byte [esi+1], 0x0f
        .wait_read:
            in al, dx
            and al, 0xC0
            cmp al, 0x40
            jne .wait_read
        mov edi, 0x100000
        xor edx, edx
        mov dx, 0x1f0
        xor ebx, ebx
        mov byte [esi], 'B'
        mov byte [esi+1], 0x0f
        .loop_kernel_write:
            mov ecx, 256
            .read:
                in ax, dx
                stosw
                loop .read
                .wait_read_kernel:
                    mov dx, 0x1f7
                    in al, dx
                    and al, 0xC0
                    cmp al, 0x40
                    jne .wait_read_kernel
                    mov dx, 0x1f0
                inc ebx
                cmp ebx, 120
                jne .loop_kernel_write
                mov byte [esi], 'J'
                mov byte [esi+1], 0x0f
        jmp 0x100000


    int_15_err:
        mov ah, 0xe
        mov al, 'M'
        int 0x10
        mov cx, 0x1f
        jmp wait_loop
    a20_nac:
        mov ah, 0xe
        mov al, 'F'
        int 0x10
        mov cx, 0x1f
        jmp wait_loop
    a20_ns: ;no support
        mov ah, 0xe
        mov al, 'Q'
        int 0x10
        mov cx, 0x1f
        wait_loop:
            mov ah, 0x86
            int 0x15
            loop wait_loop
            int 0x18


;0x8000 is the start of the mem map
disk db 0x00
;LBA info
    base_io_prim equ 0x1f0
    sectorcnt equ 120
    lba_addr equ 0x0b
    lba_dr_hd db 0x00
    lba_high db 0x00
    lba_mid db 0x00
    lba_low db 0x00
dap:
    times 16 db 0
times 5120 - ($ - $$) db 0