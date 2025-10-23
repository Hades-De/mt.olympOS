[org 0x09000]
[bits 32]

;======GTD SETUP======
    GDT_setup:
        cli
        lgdt [gdt_descriptor]
        mov eax, cr0
        or eax, 1
        mov cr0, eax ;enable 32 bits
        jmp dword 0x08:seg_regs_setup   ; Jump to loaded sector

        gdt_start:
        dq 0x0000000000000000        ; null descriptor
        dq 0x00cf9a000000ffff        ; code segment: base=0, limit=4GB, flags=0x9A, gran=1
        dq 0x00cf92000000ffff        ; data segment: base=0, limit=4GB, flags=0x92, gran=1
    gdt_end:

    gdt_descriptor:
        dw gdt_end - gdt_start - 1
        dd gdt_start

;======SEGMENTED REGISTERS SETUP======
    seg_regs_setup:
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

;======INTERRUPT TABLE ENTRIES + PIC SETUP======
    idt_int_setup:
        mov edi, 0x00
        mov eax, Div_zero
        call make_idt_entry
        ;
        mov edi, 0x01
        mov eax, Debug
        call make_idt_entry
        ;
        mov edi, 0x02
        mov eax, Non_mask_int
        call make_idt_entry
        ;
        mov edi, 0x03
        mov eax, Break
        call make_idt_entry
        ;
        mov edi, 0x04
        mov eax, Overflow
        call make_idt_entry
        ;
        mov edi, 0x05
        mov eax, Bound_range_Exceeded
        call make_idt_entry
        ;
        mov edi, 0x06
        mov eax, Invalid_opcode
        call make_idt_entry
        ;
        mov edi, 0x07
        mov eax, Device_not_available
        call make_idt_entry
        ;
        mov edi, 0x08
        mov eax, Double_fault
        call make_idt_entry
        ;
        mov edi, 0x09
        mov eax, Coproc_overrrun
        call make_idt_entry
        ;
        mov edi, 0x0A
        mov eax, Invalid_TTS
        call make_idt_entry
        ;
        mov edi, 0x0B
        mov eax, Seg_not_pres
        call make_idt_entry
        ;
        mov edi, 0x0C
        mov eax, Stack_seg_fault
        call make_idt_entry
        ;
        mov edi, 0x0D
        mov eax, Gen_prot_fault
        call make_idt_entry
        ;
        mov edi, 0x0E
        mov eax, Page_fault
        call make_idt_entry
        PIC_unmask:
            ; Send ICW1 (initialize PICs)
            mov al, 0x11
            out 0x20, al       ; master PIC
            out 0xA0, al       ; slave PIC

            ; Send ICW2 (vector offset)
            mov al, 0x20       ; remap master to 0x20-0x27
            out 0x21, al
            mov al, 0x28       ; remap slave to 0x28-0x2F
            out 0xA1, al

            ; Send ICW3 (wiring info)
            mov al, 0x04       ; slave on IRQ2
            out 0x21, al
            mov al, 0x02       ; cascade identity
            out 0xA1, al

            ; Send ICW4 (environment info)
            mov al, 0x01
            out 0x21, al
            out 0xA1, al

            mov edi, 0x2E
            mov eax, Disk_ATA_Handler
            call make_idt_entry

            mov al, 0b11111011
            out 0x21, al
            mov al, 0b10111111 
            out 0xA1, al

;======KERNEL======
    lidt [idt_ptr]
    sti

    hechloopd:
        mov dx, 0x3F6
        mov al, 0x04        ; SRST on, nIEN cleared
        out dx, al
        jmp $+2
        mov al, 0x00        ; SRST off
        out dx, al
        call ready_check
        mov dword [LBA_address], 0x0b
        mov dword [buffer_disk], 0x100000
        mov dword [sector], 100
        call load_LBA
        .loop:
            call ready_check
            cmp byte [disk_able], 0
            je .loop
            cmp byte [sector], 0
            je load_vga_driver
            jmp .loop
    load_vga_driver:
        jmp $+2
        call ready_check
        jmp $+2
        mov dword [LBA_address], 0x6f
        mov dword [buffer_disk], 0x1C8000
        mov dword [sector], 1
        jmp $+2
        call load_LBA
        jmp $+2
        jmp $+2
        .loop:
            call ready_check
            cmp byte [disk_able], 0
            je .loop
            cmp byte [sector], 0
            je load_keyboard_driver
            jmp .loop

        load_keyboard_driver:
        jmp $+2
        call ready_check
        jmp $+2
        mov dword [LBA_address], 0x70
        mov dword [buffer_disk], 0x1C8200
        mov dword [sector], 3
        jmp $+2
        call load_LBA
        jmp $+2
        jmp $+2
        .loop:
            call ready_check
            cmp byte [disk_able], 0
            je .loop
            cmp byte [sector], 0
            je jump_to_kernel
            jmp .loop


    jump_to_kernel:
        mov al, 0b11111101
        out 0x21, al
        mov al, 0xFF
        out 0xA1, al
        mov al, 0x20
        jmp dword 0x08:0x100000

;======IDT FAULT INTERRUPTS======
    exec_idt:
        Div_zero:
            pusha
            mov ah, 0x04
            mov ebx, zero
            call print
            popa
            cli
            hlt
            jmp $

        Debug:
            pusha
            mov ah, 0x04
            mov ebx, debug
            call print
            popa
            cli
            hlt
            jmp $

        Non_mask_int:
            pusha
            mov ah, 0x04
            mov ebx, nmi
            call print
            popa
            cli
            hlt
            jmp $
            
        Break:
            pusha
            mov ah, 0x04
            mov ebx, breakp
            call print
            popa
            cli
            hlt
            jmp $
            
        Overflow:
            pusha
            mov ah, 0x04
            mov ebx, zero
            call overf
            popa
            cli
            hlt
            jmp $
            
        Bound_range_Exceeded:
            pusha
            mov ah, 0x04
            mov ebx, bre
            call print
            popa
            cli
            hlt
            jmp $
            
        Invalid_opcode:
            pusha
            mov ah, 0x04
            mov ebx, inop
            call print
            popa
            cli
            hlt
            jmp $
            
        Device_not_available:
            pusha
            mov ah, 0x04
            mov ebx, dna
            call print
            popa
            cli
            hlt
            jmp $
            
        Double_fault:
            pusha
            mov ah, 0x04
            mov ebx, df
            call print
            popa
            cli
            hlt
            jmp $
            
        Coproc_overrrun:
            pusha
            mov ah, 0x04
            mov ebx, cso
            call print
            popa
            cli
            hlt
            jmp $
            
        Invalid_TTS:
            pusha
            mov ah, 0x04
            mov ebx, intts
            call print
            popa
            cli
            hlt
            jmp $
            
        Seg_not_pres:
            pusha
            mov ah, 0x04
            mov ebx, snp
            call print
            popa
            cli
            hlt
            jmp $
            
        Stack_seg_fault:
            pusha
            mov ah, 0x04
            mov ebx, ssf
            call print
            popa
            cli
            hlt
            jmp $
            
        Gen_prot_fault:
            pusha
            mov ah, 0x04
            mov ebx, gpf
            call print
            popa
            cli
            hlt
            jmp $
            
        Page_fault:
            pusha
            mov ah, 0x04
            mov ebx, pf
            call print
            popa
            cli
            hlt
            jmp $

;======KEYBOARD, TIMER, DISK HANDLERS======
Disk_ATA_Handler:
            pusha
            mov edi, [buffer_disk]
            read_from_disk:
                loop_diskread:
                    mov dx, ATA_IO_Base
                    mov ecx, 256
                    rep insw
                    mov [buffer_disk], edi    
                    xor eax, eax
                mov eax, [sector]
                dec eax
                mov [sector], eax
                mov eax, [disk_able]
                inc eax
                mov [disk_able], eax
                mov al, 0x20
                out 0x20, al            ; EOI PIC
                out 0xA0, al         ; send EOI to slave PIC
                popa
                iret


Print_Character: ;expects esi to be set, color in ah, letter byte in al, and edi to have [vid_counter]. increases [vid_counter], [buffer_ptr],
    cmp al, 0x20
    jne .print
    mov ah, 0x00
    mov al, 0x00
    .print:
        mov word [esi], ax
        add esi, 2
        cmp esi, vidmemend
        jae .reset_cursor
        .update_print_ptr:
            inc edi
            cmp edi, 80
            je .reset_vid_counter
        .return:
            mov [buffer_ptr], esi
            mov [vid_counter], edi
            ret

        .reset_cursor:
                mov esi, 0xB8000
                mov [buffer_ptr], esi
                jmp .update_print_ptr

        .reset_vid_counter:
            mov edi, 0
            jmp .return

print: ;EXPECTS EBX TO HAVE STRING, AND COLOR BYTE TO BE SET!!! in ah
    mov [color_attr_buffer], ah
    mov esi, [buffer_ptr]
    mov edi, [vid_counter]
    .print_loop:
        mov ah, [color_attr_buffer] ; just so, if we had a space in the single char print, it sets it back to what it was
        mov al, [ebx]
        test al, al
        je .return
        call Print_Character
        inc ebx
        jmp .print_loop

    .return:
            mov [buffer_ptr], esi
            mov [vid_counter], edi
            ret

load_LBA:
    in   al, 0x21        ; PIC master mask
    and  al, 0b11111011  ; clear bit 1 to enable IRQ 1 (PS/2), but that’s not us
    out 0x21, al
    in   al, 0xA1        ; PIC slave mask
    and  al, 0b10111111  ; clear bit 6 to enable IRQ14
    out  0xA1, al
    .set_read_sectors: 
        mov dx, ATA_IO_Base + 2
        mov al, [sector]
        out dx, al
    .setmaster:
        mov eax, [LBA_address]
        shr eax, 24
        and al, 0x0F
        or al, 0xE0
        mov dx, ATA_IO_Base + 6
        out dx, al
        mov dx, ATA_IO_Base + 7
        in al, dx
        in al, dx
        in al, dx
        in al, dx
    .set_lowMidHigh_bytes:
        mov eax, [LBA_address]
        mov dx, ATA_IO_Base + 3 
        out dx, al                ; al = bits 0-7
        inc dx
        shr eax, 8                ; bits 8–15 now in al
        out dx, al
        inc dx 
        shr eax, 8                ; bits 16–23 now in al
        out dx, al 
    .read:
        mov dx, ATA_IO_Base +7
        mov al, 0x20
        out dx, al 
    ready_check:
        .spinup_check:
            mov dx, ATA_IO_Base + 7
            in al, dx
            ;check for 15 sec delay, after 15 sec, ask user if they want to stop disk io
            test al, bsy ;change to spin up check
            jnz .spinup_check
        .ready_check:
            mov dx, ATA_IO_Base + 7
            in al, dx
            test al, drq
            jz .ready_check
            ret
; eax = handler address
; edi = index
make_idt_entry:
    ; Set low 16 bits of handler
    mov word [idt + edi*8 + 0], ax              
    ; Set segment selector (e.g. 0x08 for kernel code)
    mov word [idt + edi*8 + 2], 0x08            
    ; Set zero byte
    mov byte [idt + edi*8 + 4], 0               
    ; Set type + flags: 0x8E = present + ring 0 + 32-bit interrupt gate
    mov byte [idt + edi*8 + 5], 0x8E            
    ; Set high 16 bits of handler
    shr eax, 16
    mov word [idt + edi*8 + 6], ax              
    ret

idt:
    times 256 dq 0
idt_ptr:
    dw 256 * 8 - 1
    dd idt

;======VARIABLES, ERROR STRINGS, KEYBOARD MAP======
    zero db '[E]0x00 Div by 0 error!',0
    debug db '[D]0x01 Debug int!',0
    nmi db '[E]0x02 Non-maskable int error!',0
    breakp db '[D]0x03 Breakpoint int',0
    overf db '[E]0x04 Integer overflow',0
    bre db '[E]0x05 Bound range exceeded',0
    inop db '[E]0x06 Invalid Opcode',0
    dna db '[D]0x07 Device not available',0
    df db '[E]0x08 Double fault',0
    cso db '[E]0x09 Coprocessor seg overrun',0
    intts db '[E]0x0A invalid TTS',0
    snp db '[E]0x0B segment not present',0
    ssf db '[E]0x0C stack-segment fault',0
    gpf db '[E]0x0D general protection fault',0
    pf db '[E]0x0E Page fault, mem acc fail',0
    LBA_address dd 0x0b
    ATA_IO_Base equ 0x1F0  
    sector dd 0            
    drq equ 0x40 ;ready
    bsy equ 0x80 ;busy
    def equ 0x20 ;device fault
    err equ 0x01 ;command fail
    buffer_disk dd 0x100000
    vidmemend equ 0xB8F9E
    disk_able dd 1
    vid_counter dd -1
    color_attr_buffer db 0
    buffer_ptr dd 0xB8000
times 5120 - ($ - $$) db 0