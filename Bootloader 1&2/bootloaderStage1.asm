[bits 16]
[org 0x7C00]

start:
    cli 
    mov sp, 0x7F00 ; set the stack
    sti 
    in al, 0x92
    or al, 00000010b
    and al, 11111110b
    out 0x92, al
    ; Save drive number
    mov [boot_drive], dl

    ; check_LBA_support if supported,return carry0
        mov ax, 0x41
        mov bx, 0x55AA ;add back dl if broken
        int 0x13
        jc no_lba_supprt

    ; Setup DAP (Disk Address Packet)
    mov byte [dap], 0x10      ; Size
    mov byte [dap+1], 0x00
    mov word [dap+2], 10      ; 2 sectors
    mov word [dap+4], 0x0000  ; offset
    mov word [dap+6], 0x0900  ; segment
    mov dword [dap+8], 1      ; LBA = 1
    mov dword [dap+12], 0     ; LBA high

    ; Call INT 13h, AH=42h (Extended Read)
    mov si, dap ;move the DAP into SI
    mov dl, [boot_drive] ;move the drive number back into dl
    mov ah, 0x42
    int 0x13
    jc disk_error ;failed to read from the disk
    cmp ah, 0 ;ah 0 = fail
    jne disk_error
    jmp secondstage

    no_lba_supprt:;; will also transform LBA > CHS
            mov dl, [boot_drive]
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
            mov dl, [boot_drive]
            cmp cl, 0
            je disk_error
            int 0x13
            jc disk_error
            cmp ah, 0
            je secondstage
            cmp ah, 0
            jne disk_error

secondstage:   
    mem_detection:
        Low_Mem_Detection:
            int 0x12 ;asks for the low memory, size in ax
            jc error ;jumps if it failed (it shouldn't on any normal system)
            cmp ax, 639 ; 639, because the count starts at 0.
            jl Low_memory

        high_mem_detection:
            prep:
                mov ax, 0         ; ES = 0
                mov es, ax
                mov di, 0x8000    ; ES:DI points to 0x0000:0x8000
                xor ebx, ebx      ; EBX must be zero for the first call
                xor eax, eax
                xor ecx, ecx
                mov eax, 0xE820   ; E820 memory map call
                mov edx, 0x534D4150 ; 'SMAP'
                mov ecx, 24       ; We request 24 bytes (what BIOS supports)
                int 0x15
                jc error
                cmp eax, 0x534D4150
                jne error

            .loop:
                ; Padding remaining 8 bytes to make 32-byte entries
                ; First pad the last 8 bytes to 0 (manual padding)
                mov si, di
                add si, 24
                mov dword [es:si], 0
                mov dword [es:si+4], 0

                add di, 32
                add word [0x8000], 32

                ; Prepare next call
                mov eax, 0xE820
                mov edx, 0x534D4150
                mov ecx, 24
                int 0x15

                jc continue
                cmp eax, 0x534D4150
                jne error
                test ebx, ebx
                jnz .loop
                jmp continue
                                            
        error:
            mov ah, 0x0E
            mov al, 'E'
            int 0x10
            jmp $

        Low_memory:
            mov ah, 0x0E
            mov al, 'L'
            int 0x10
            jmp $
    continue:
        cli
        lgdt [GDT_Descriptor]
        mov eax, cr0
        or eax, 1
        mov cr0, eax
        jmp dword 0x08:0x09000    ; Jump to loaded sector

        GDT_Start:
            null_descriptor:
                dd 0
                dd 0
            code_descriptor:
                dw 0xFFFF
                dw 0
                db 0
                db 0b10011010
                db 0b11001111
                db 0
            data_descriptor:
                dw 0xFFFF
                dw 0
                db 0
                db 0b10010010
                db 0b11001111
                db 0
            GDT_End:

        GDT_Descriptor:
            dw GDT_End - GDT_Start -1 ; size
            dd GDT_Start

        disk_error:
            mov ah, 0x0E
            mov al, 'D'
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
