bits 16
[org 0x8000]

start:
    cli
    mov ax, 0x8000
    mov ds, ax      ; <-- this is critical!
    mov es, ax
    xor ax, ax
    mov ss, ax
    mov si, ax
    sti
    ; Print '2'
    mov ah, 0x0E
    mov al, '2'
    int 0x10   
        ; Setup DAP (Disk Address Packet)
    mov byte [dap], 0x10      ; Size
    mov byte [dap+1], 0x00
    mov word [dap+2], 5       ; 2 sector
    mov word [dap+4], 0x0000  ; offset
    mov word [dap+6], 0x9000 ; segment (change if needed)
    mov dword [dap+8], 1      ; LBA = 1
    mov dword [dap+12], 0     ; LBA high

stack_Subroutine: ;ONLY USES AX FOR PUSHING, ALL OTHER REGS ARE PRESERVED
    stack_setup:
        mov [CX_storage], cx
        mov cx, 0x7bf6
        mov [current_loc], cx
        mov sp, [current_loc]
        mov cx, [CX_storage]
        mov ah, 0x0E
        mov al, 's'
        int 0x10
        jmp mem_detection

    add_to_stack: ; we assume everything added to the stack is a 2 byte thingy, stored in AX
        sub word [current_loc], 2
        jc stack_full ; we check if theres space for 2 bytes in the current location, if carry bit set its already fucked.
        cmp word [current_loc], 0x0600 ; because thats where our stack stops
        jle stack_full ; if its bellow 0x0500 we say its full. no shame, nothing done.
        push ax
        ret

    pop_from_stack: ; we assume everything added to the stack is a 2 byte thingy, stored in AX
        add word [current_loc], 2
        jc stack_empty ; we check if theres space for 2 bytes in the current location, if carry bit set its already fucked.
        cmp word [current_loc], 0x7BF7
        jge stack_empty ; if its above 0x7BF7 we say its empty. no shame, nothing done.
        pop ax
        ret

    stack_empty:
        sub word [current_loc], 2
        mov ah, 0x0E
        mov al, 'S'
        int 0x10
        ret

    stack_full:
        add word [current_loc], 2
        mov ah, 0x0E
        mov al, 'F'
        int 0x10
        ret

mem_detection:
    Low_Mem_Detection:
        clc
        int 0x12 ;asks for the low memory, size in ax
        jc error ;jumps if it failed (it shouldn't on any normal system)
        cmp ax, 639 ; 639, because the count starts at 0.
        jl Low_memory
        mov ah, 0x0E
        mov al, 'l'
        int 0x10

    high_mem_detection:
        prep:
            mov ax, 0         ; ES = 0
            mov es, ax
            mov di, 0x8500    ; ES:DI points to 0x0000:0x8500
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
            add word [length_mem_map], 32

            ; Prepare next call
            mov eax, 0xE820
            mov edx, 0x534D4150
            mov ecx, 24
            int 0x15

            jc done_reading
            cmp eax, 0x534D4150
            jne error
            test ebx, ebx
            jnz .loop


            done_reading:
                mov ah, 0x0E
                mov al, 'm'
                int 0x10 ; display "m" to say that high mem part is done
                mov si, 0x8500
                mov eax, [es:si + 0]   ; base addr low. We wont need edx for this
                mov edx, [es:si + 4]   ; base addr high
                mov ebx, [es:si + 8]   ; length low
                mov ecx, [es:si + 12]  ; length high
                cmp edx, 0
                jg continue ; somewhere to where we "upload" the map
                mov edx, [es:si + 16] ;move the id into edx
                cmp edx, 1 ;checks if its usable
                jg skip ;1> non usable
                add si, 32
                cmp si, di
                jmp kernellocation_setup

                skip: 
                    add si, 32; we add 32 to si to get to the next location
                    cmp si, di ;check if we're done
                    jge continue
                    jmp done_reading

                kernellocation_setup:
                    mov [kernel_loc], eax ; move the location to 0x0500, we will read it from here, make a new location. and then fix this, since assembly cant really understand variables outside of registeres
                    mov [kernel_loc +5], ebx
                    mov [kernel_loc +9], ecx ;length is starting at 0x0505, we leave one byte emtpy between the location and the length

                    
                
                    

                        
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
    ; Print 'H'
    mov ah, 0x0E
    mov al, 'H'
    int 0x10  

hlt
jmp $

;;diskIO should always be last, and halted right before. because we do *not* want to accidentally load this crap.
DiskIO_Subroutine:
    hceck_LBA_supprt: ;if supported,return carry0
    mov ax, 0x41
    mov bx, 0x55AA
    mov dl, [boot_drive]
    int 0x13
    jc no_lba_supprt
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
                clc
                mov bx, 0x8200
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
        mov ah, 0x0E
        mov al, 'm'
        int 0x10
        jmp 0x8200:0000     ; Jump to loaded sector

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
stack_max: dw 0x7BF6 ;7BF6 till 0x0500, yes really that much stack space. i'll be thankfull later
CX_storage: dw 0x7BF7 ;stores CX for the calculation
Push_thing: dw 0x7BF8 ;stores the thing we want to push for the time being, so that we can calculate if we have enough space
current_loc: dw 0x7BFF ;stores the amount we still have. in a 64 bit thing. just to be sure.
kernel_loc: dw 0x0500
length_mem_map: dd 0x8400
VESA_MAP: dw 0x8300

dap: times 16 db 0

;file storage




times 1024 - ($ - $$) db 0
