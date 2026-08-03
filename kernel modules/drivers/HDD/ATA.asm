[org 0x10ea00]
[bits 32]

init:
    pop ebp
        mov eax, read_lba_28b
        mov ebx, destinat
        mov ecx, write_lba_28b
        push eax
        push ebx
        push ecx
    push ebp
    ret


setup_lba_28b: ;expects eax to hold lba and ebx seccnt, edi dest
        mov dword [lba_addr], eax
        mov dword [destinat], edi
        mov byte [sectorcnt], bl

        .lba_translate:
            mov eax, [lba_addr]
            and eax, 0xff
            mov byte [lba_low], al
            mov eax, [lba_addr]
            shr eax, 8
            and eax, 0xff
            mov byte [lba_mid], al
            mov eax, [lba_addr]
            shr eax, 16
            and eax, 0xff
            mov byte [lba_high], al
            mov eax, [lba_addr]
            shr eax, 24
            and eax, 0x0f
            mov byte [lba_dr_hd], al

        mov al, [lba_dr_hd]
        or al, 0xE0
        mov dx, base_io_prim+6
        out dx, al 
        mov al, [sectorcnt]
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
        .wait:
            in al, dx
            and al, 0xC0
            cmp al, 0x40
            jne .wait
        ret

read_lba_28b: 
    call setup_lba_28b   
    mov al, 0x20
    out dx, al
    ret

write_lba_28b:
    call setup_lba_28b   
    mov al, 0x30
    out dx, al
    mov dx, 0x1F0
    mov esi, [destinat]
    mov ecx, 256
    .write:
        lodsw
        out dx, ax
        loop .write

    mov dx, 0x1f7
    mov ax, 0xe2
    out dx, ax
    .wait_done:
        xor ax, ax
        in ax, dx
        test ax, 0x80       ; BSY
        jnz .wait_done
    ret

;io_ports
    base_io_prim equ 0x1f0
    base_ctrl_prim equ 0x3f6
    base_io_sec equ 0x170
    base_ctrl_sec equ 0x376
;LBA info
    destinat dd 0x00
    sectorcnt db 0x00
    lba_addr dd 0x00
    lba_dr_hd db 0x00
    lba_high db 0x00
    lba_mid db 0x00
    lba_low db 0x00

times 512 - ($ - $$) db 0