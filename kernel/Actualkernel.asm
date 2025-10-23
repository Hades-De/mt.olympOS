[org 0x100000]
[bits 32]
cli
;======SEGMENTED REGISTERS SETUP======
    seg_regs_setup:
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
        mov dl, start_vga
        call print
        mov dl, clr_scr
        call print
        mov ebx, Gdt_init
        mov ah, 0x0f
        mov dl, print_char | loop_func
        call print
        call init_ok
        mov dl, N_line
        call print
        jmp idt_int_setup

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

            mov edi, 0x20
            mov eax, timer
            call make_idt_entry

            ;mov edi, 0x21
            ;mov eax, keyboard
            ;call make_idt_entry

            ;mov edi, 0x2E
            ;mov eax, Disk_ATA_Handler
            ;call make_idt_entry

            mov al, 0b11111110
            out 0x21, al
            mov al, 0b10111111 
            out 0xA1, al

;======KERNEL======
    lidt [idt_ptr]
    sti
    init_list:
        int 0x01 ; test IDT
        call 0x1c8200
        call Convert_to_dec
        mov ah, 0x0f
        mov dl, print_char | loop_func
        call print
        mov ebx, RAM
        mov ah, 0x0f
        mov dl, print_char | loop_func
        call print
        mov dl, N_line
        call print

        xor edi, edi
        mov dl, 0b00000001
        call 0x1c8400
        mov dl, N_line
        call print

        mov ecx, 159
        call 0x1c8400
        mov ecx, 14
        call 0x1c8400

    Kernel_loop:
        jmp $


tet:
    xor ebx, ebx
    xor edi, edi
    find_non_used_map:
    mov esi, [map_start + edi + 16] ; load current map (only the used byte)
    test esi, esi ;test if its used
    je not_used
    test eax, eax ;test if eax si empty, if it is, pretty likely its out of maps
    je nospace
    add edi, 32
    jmp find_non_used_map

not_used:
    mov ebx, free
    mov ah, 0x0f
    mov dl, print_char | loop_func
    call print
   ;pop ecx
    ret

nospace:
    mov ebx, nospc
    mov ah, 0x0f
    mov dl, print_char | loop_func
    call print
    ;pop ecx
    ret

Convert_to_dec:
        mov eax, [0x500]
        mov ecx, 10        ; divisor
        xor edx, edx       ; clear remainder
        mov ebx, buf+10    ; end of buffer
        mov byte [ebx], 0  ; null-terminate the string
        dec ebx            ; move back to fill digits

        .convert_loop:
                xor edx, edx
                div ecx            ; divide eax by 10, quotient in eax, remainder in edx
                add dl, '0'        ; convert remainder to ASCII
                mov [ebx], dl
                dec ebx
                test eax, eax
                jnz .convert_loop

                inc ebx            ; ebx now points to the first character of the string
                mov [0x500], ebx
                ret

;======IDT FAULT INTERRUPTS======
    exec_idt:
        Div_zero:
            pusha
            mov ah, 0x04
            mov ebx, zero
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $

        Debug:
            pusha
            mov ebx, Idt_init
            mov ah, 0x0f
            mov dl, print_char | loop_func
            call print
            call init_ok
            mov dl, N_line
            call print
            popa
            iret

        Non_mask_int:
            pusha
            mov ah, 0x04
            mov ebx, nmi
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Break:
            pusha
            mov ah, 0x04
            mov ebx, breakp
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Overflow:
            pusha
            mov ah, 0x04
            mov ebx, overf
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Bound_range_Exceeded:
            pusha
            mov ah, 0x04
            mov ebx, bre
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Invalid_opcode:
            pusha
            mov ah, 0x04
            mov ebx, inop
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Device_not_available:
            pusha
            mov ah, 0x04
            mov ebx, dna
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Double_fault:
            pusha
            mov ah, 0x04
            mov ebx, df
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Coproc_overrrun:
            pusha
            mov ah, 0x04
            mov ebx, cso
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Invalid_TTS:
            pusha
            mov ah, 0x04
            mov ebx, intts
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Seg_not_pres:
            pusha
            mov ah, 0x04
            mov ebx, snp
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Stack_seg_fault:
            pusha
            mov ah, 0x04
            mov ebx, ssf
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Gen_prot_fault:
            pusha
            mov ah, 0x04
            mov ebx, gpf
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $
            
        Page_fault:
            pusha
            mov ah, 0x04
            mov ebx, pf
            mov dl, print_char | loop_func
            call print
            popa
            cli
            hlt
            jmp $

;======KEYBOARD, TIMER, DISK HANDLERS======
timer:
    inc dword [timer_counter]
    cmp dword [timer_counter], 18
    jl .done

    mov dword [timer_counter], 0
    inc dword [seconds_passed]   ; 1 second passed!

.done:
    ; send EOI to PIC
    mov al, 0x20
    out 0x20, al
    iret

screen_functions:
    init_ok:
        mov ah, 0x0f ; white
        mov dl, print_char
        call print
        mov al, '['
        mov dl, print_char
        call print
        xor ax, ax
        mov ah, 0x02 ; green
        mov ebx, ok
        mov dl, print_char | loop_func
        call print
        mov ah, 0x0f ; white
        mov al, ']'
        mov dl, print_char
        call print
        ret

    init_failed:
        mov ah, 0x0f ; white
        mov dl, print_char
        call print
        mov al, '['
        mov dl, print_char
        call print
        xor ax, ax
        mov ah, 0x04 ; red
        mov ebx, failed
        mov dl, print_char | loop_func
        call print
        mov ah, 0x0f ; white
        mov al, ']'
        mov dl, print_char
        call print
        ret

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

    print_timer: ;EXPECTS EBX TO HAVE STRING, AND COLOR BYTE TO BE SET!!! in ah
        mov [color_attr_buffer], ah
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
    noCom db 'no command found!',0
    noFil db 'no File found!',0
    no_space db 'no space left!',0
    Gdt_init db 'GDT Init',0
    Idt_init db 'IDT Init',0
    failed db 'FAILED',0
    ok db 'OK',0
    RAM db ' Bytes of ram detected!', 0
    buf dw 0x00
    map_start equ 0x1c8600
    nospc db "No RAM left, please wait with loading files!",0
    free db "memory free!",0
    timer_counter dd 0
    seconds_passed dd 0
    ;vga driver
        print_char equ 0b00000001
        loop_func  equ 0b00000010
        res_scr    equ 0b00000100
        clr_scr    equ 0b00001000
        N_line     equ 0b00010000
        start_vga  equ 0b00100000
        print      equ 0x1c8000
    read_loc dd 0
    buffer_ptr dd 0xB8F00
    vidmemend equ 0xB8F9E
    vid_counter dd -1
    color_attr_buffer db 0
    lookup_table:
        db "mem "
        db "vga "
        times 512 - 12 db 0
    file_table:
        ;memmap maker
        dd 0x0000007E ;LBA loc
        dd 0x00000001 ;number of sectors
        db 0b00111001 ;file perms
        ;vga driver
        dd 0x0000006F
        dd 0x00000001
        db 0b00111101

        times 4608 - 27 db 0 ; exactly 9 times 512 bytes
times 51200 - ($ - $$) db 0xff