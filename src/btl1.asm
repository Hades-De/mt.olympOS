[org 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7F00
    sti

    ; Save drive number
    mov [boot_drive], dl

    ; Print 'L'
    mov ah, 0x0E
    mov al, 'L'
    int 0x10

    hceck_LBA_supprt: ;if supported,return carry0
        mov ax, 0x41
        mov bx, 0x55AA
        mov dl, [0x7e10]
        int 0x13
        jc no_lba_supprt

    ; Setup DAP (Disk Address Packet)
    mov byte [dap], 0x10      ; Size
    mov byte [dap+1], 0x00
    mov word [dap+2], 1       ; 1 sector
    mov word [dap+4], 0x0000  ; offset
    mov word [dap+6], 0x8000  ; segment
    mov dword [dap+8], 1      ; LBA = 1
    mov dword [dap+12], 0     ; LBA high

    ; Call INT 13h, AH=42h (Extended Read)
    mov si, dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc disk_error
    cmp ah, 0
    jne disk_error
    jmp secondstage

no_lba_supprt:;; will also transform LBA > CHS
            mov dl, [0x7e10]
            cmp dl, 0x80
            jl disk_error ;;we do this because CHS doesnt like floppy detecting like this
            mov ah, 8
            int 0x13
            mov [Nhe], dh
            and cl, 0x3f
            mov [SpT], cl;;with 0x3f whatever thats supposed to mean
            Translate_Lba_Chs:
                mov ax, [dap + 8] ; low word of LBA
                xor dx, dx              ; clear upper part of dividend
                mov cx, [SpT]           ; sectors per track
                div cx                  ; ax = LBA / SPT, dx = LBA % SPT
                inc dx                  ; sector numbers start from 1
                mov [Sec], dx           ; store sector
                mov [Tmp], ax           ; store temp result
                mov ax, [Tmp]
                xor dx, dx
                mov cx, [Nhe]           ; heads per cylinder
                div cx                  ; ax = cylinders, dx = heads
                mov [Cyl], ax
                mov [Hed], dx

        Read_CHS:
            clc
            mov bx, 0x8000
            mov ah, 0x02
            mov ch, [Cyl]         ; CH = Cylinder low 8 bits
            mov cl, [Sec]         ; CL = Sector number (1–63)
            mov ax, [Cyl]
            mov ch, al        ; low 8 bits
            mov al, ah
            shl al, 6         ; top 2 bits into bits 6–7
            or cl, al            ; merge with sector into CL             ; inject upper 2 bits of cylinder into CL
            mov dh, [Hed]
            mov dl, [0x7e10]
            cmp cl, 0
            je disk_error
            int 0x13
            jc disk_error
            cmp ah, 0
            je secondstage
            cmp ah, 0
            jne disk_error
secondstage:
    mov ah, 0x0E
    mov al, 'S'
    int 0x10
    jmp 0x8000:0000     ; Jump to loaded sector

disk_error:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10
    jmp $

boot_drive: db 0
Nhe: db 0
SpT: db 0
Tmp: db 0
Sec: db 0
Hed: db 0
Cyl: db 0

dap: times 16 db 0

times 510 - ($ - $$) db 0
dw 0xAA55
