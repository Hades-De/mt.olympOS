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
    lib_init:
        call 0x10c800
        pop ecx
        pop ebx
        pop eax
        pop edx
        pop esi
        mov dword [print_tty], ecx
        mov dword [setup_xy], ebx
        mov dword [print_xy], eax
        mov dword [bin_hex], edx
        mov dword [newLine] , esi
        xor ecx, ecx
        xor edx, edx
        call [setup_xy]
        mov ebx, Gdt_init
        mov eax, ram_detect - Gdt_init -1
        call [print_tty]
        call [newLine]
    memory_init:
        call 0x10c400
        pop ecx
        pop eax
        pop ebx
        mov dword [dump_mem], eax
        mov dword [page_walk], ebx
        mov dword [Valloc], ecx
        mov eax, [0x504]
        call [bin_hex]
        mov eax, [0x500]
        call [bin_hex]
        mov ebx, ram_detect
        mov eax, offset_page - ram_detect -1
        call [print_tty]
        call [newLine]   
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

            mov al, 0b11111111
            out 0x21, al
            mov al, 0b10111111 
            out 0xA1, al

;======KERNEL======  
    xor edi, edi
    mov ebx, 0x349B2E
    mov eax, [print_tty]
    call irq_timer
    call [newLine]
    lidt [idt_ptr]
    sti
    init_list:
        mov eax, 0x500000
        call Dump_Pagewalk
        call [newLine]
        mov ebx, 0x500000
        mov eax, 4
        call [Valloc]
        mov ebx, 0x505000
        mov eax, 4
        call [Valloc]
        mov dword [0x500000], 0x12345678
        mov eax, [0x500000]
        call [bin_hex]
        mov dword [0x505000], 0x87654321
        mov eax, [0x505000]
        call [bin_hex]
    Kernel_loop:
        jmp Kernel_loop
;0010ce5c

Dump_regs:
        call [newLine]
        pop ebp
        mov ebx, reg_edi
        mov eax, reg_esi - reg_edi -1
        call [print_tty]
        pop eax
        call [bin_hex]
        mov ebx, reg_esi
        mov eax, reg_ebp - reg_esi -1
        call [print_tty]
        pop eax
        call [bin_hex]
        mov ebx, reg_ebp
        mov eax, reg_esp - reg_ebp -1
        call [print_tty]
        pop eax
        call [bin_hex]
        call [newLine]
        mov ebx, reg_esp
        mov eax, reg_ebx - reg_esp -1
        call [print_tty]
        pop eax
        call [bin_hex]
        mov ebx, reg_ebx
        mov eax, reg_edx - reg_ebx -1
        call [print_tty]
        pop eax
        call [bin_hex]
        mov ebx, reg_edx
        mov eax, reg_ecx - reg_edx -1
        call [print_tty]
        pop eax
        call [bin_hex]
        call [newLine]
        mov ebx, reg_ecx
        mov eax, reg_eax - reg_ecx -1
        call [print_tty]
        pop eax
        call [bin_hex]
        mov ebx, reg_eax
        mov eax, cr_cr0 - reg_eax -1
        call [print_tty]
        pop eax
        call [bin_hex]
        push ebp
        ;now cr0-2-3-4
        call [newLine]
        mov ebx, cr_cr0
        mov eax, cr_cr2 - cr_cr0 -1
        call [print_tty]
        mov eax, cr0
        call [bin_hex]
        mov ebx, cr_cr2
        mov eax, cr_cr3 - cr_cr2 -1
        call [print_tty]
        mov eax, cr2
        call [bin_hex]
        mov ebx, cr_cr3
        mov eax, cr_cr4 - cr_cr3 -1
        call [print_tty]
        mov eax, cr3
        call [bin_hex]
        mov ebx, cr_cr4
        mov eax, Gdt_init - cr_cr4 -1
        call [print_tty]
        mov eax, cr4
        call [bin_hex]
        call [newLine]
        ret

Dump_Pagewalk:; expects eax to hold the Vmem loc
        call [page_walk]
        pop eax
        call [bin_hex]
        mov ebx, pde
        mov eax, space - pde -1
        call [print_tty]
        pop eax
        call [bin_hex]
        mov ebx, pte
        mov eax, pde - pte -1
        call [print_tty]
        pop eax
        call [bin_hex]
        mov ebx, offset_page
        mov eax, pte - offset_page -1
        call [print_tty]
        ret

Dump_mem_loc:
        call [dump_mem]
        xor ecx, ecx
        .loop:
            pop eax
            push ecx
            call [bin_hex]
            mov ebx, space
            mov eax, Idt_init - space -1
            call [print_tty]
            pop ecx
            inc ecx
            cmp ecx, 32
            jl .loop
            ret
;======IDT FAULT INTERRUPTS======
    exec_idt:
        Div_zero:
            pusha
            mov ebx, Div_zero
            mov eax, debug - Div_zero -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $

        Debug:
            pusha
            mov ebx, debug
            mov eax, nmi - debug -1
            call [print_tty]
            call Dump_regs
            cli
            iret

        Non_mask_int:
            pusha
            mov ebx, nmi
            mov eax, breakp - nmi -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Break:
            pusha
            mov ebx, breakp
            mov eax,  overf - breakp -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Overflow:
            pusha
            mov ebx, overf
            mov eax, bre - overf -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Bound_range_Exceeded:
            pusha
            mov ebx, bre
            mov eax, inop - bre -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Invalid_opcode:
            pusha
            mov ebx, inop
            mov eax, dna - inop -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Device_not_available:
            pusha
            mov ebx, dna
            mov eax, df - dna -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Double_fault:
            pusha
            mov ebx, df
            mov eax, cso - df -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Coproc_overrrun:
            pusha
            mov ebx, cso
            mov eax, intts - cso -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Invalid_TTS:
            pusha
            mov ebx, intts
            mov eax, snp - intts -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Seg_not_pres:
            pusha
            mov ebx, snp
            mov eax, ssf - snp -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Stack_seg_fault:
            pusha
            mov ebx, ssf
            mov eax, gpf - ssf -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Gen_prot_fault:
            pusha
            mov ebx, gpf
            mov eax, pf - gpf -1
            call [print_tty]
            call Dump_regs
            cli
            hlt
            jmp $
            
        Page_fault:
            pusha
            mov ebx, pf
            mov eax, reg_edi - pf -1
            call [print_tty]
            mov eax, [esp+32] ; page fault error code
            call [bin_hex]
            call Dump_regs
            cli
            hlt
            jmp $

;======KEYBOARD, TIMER, DISK HANDLERS======
    timer:
        mov ebx, Timer_msg
        mov eax, text_end - Timer_msg -1
        call [print_tty]
        iret

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
    zero db '[E]0x00 Div by 0 error!'
    debug db '[D]0x01 Debug int!'
    nmi db '[E]0x02 Non-maskable int error!'
    breakp db '[D]0x03 Breakpoint int'
    overf db '[E]0x04 Integer overflow'
    bre db '[E]0x05 Bound range exceeded'
    inop db '[E]0x06 Invalid Opcode'
    dna db '[D]0x07 Device not available'
    df db '[E]0x08 Double fault'
    cso db '[E]0x09 Coprocessor seg overrun'
    intts db '[E]0x0A invalid TTS'
    snp db '[E]0x0B segment not present'
    ssf db '[E]0x0C stack-segment fault'
    gpf db '[E]0x0D general protection fault'
    pf db '[E]0x0E Page fault, mem acc fail'
    reg_edi db ' edi '
    reg_esi db ' esi '
    reg_ebp db ' ebp '
    reg_esp db ' esp '
    reg_ebx db ' ebx '
    reg_edx db ' edx '
    reg_ecx db ' ecx '
    reg_eax db ' eax '
    cr_cr0  db ' cr0 '
    cr_cr2  db ' cr2 '
    cr_cr3  db ' cr3 '
    cr_cr4  db ' cr4 '
    Gdt_init db '[OK] GDT Init'
    ram_detect db ` bytes of ram detected`
    offset_page db ` offset `
    pte db ` Page Table `
    pde db ` Page Directory `
    space db ` `
    Idt_init db '[OK] IDT Init'
    Timer_msg db "time tick "
    text_end db 0x00

    ;mmu
            Valloc dd 0x00
    ;debug
            page_walk dd 0x00
            dump_mem dd 0x00
    ;vga driver
            irq_timer equ 0x10Cc00 
            print_xy dd 0x00
            print_tty dd 0x00
            setup_xy dd 0x00
            bin_hex dd 0x00
            newLine dd 0x00

    ;colors
        black    equ 0x00
        blue     equ 0x01
        green    equ 0x02
        cyan     equ 0x03
        red      equ 0x04
        purple   equ 0x05
        brown    equ 0x06
        gray     equ 0x07
        D_gray   equ 0x08
        L_blue   equ 0x09
        L_green  equ 0x0a
        L_cyan   equ 0x0b
        L_red    equ 0x0c
        L_purple equ 0x0d
        yellow   equ 0x0e
        white    equ 0x0f
times 50176 - ($ - $$) db 0xee