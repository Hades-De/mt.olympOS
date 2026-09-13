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
        mov ebp, esp
        sub ebp, 0x200;for init's
        xor di, di
        xor ax, ax
    lib_init:
        call 0x10c800
        mov eax, esp
        mov esp, ebp
        mov ebp, eax
        pop eax
        mov dword [clear_screen], eax
        popa
        mov dword [print_tty], ecx
        mov dword [setup_xy], ebx
        mov dword [print_xy], eax
        mov dword [bin_hex], edx
        mov dword [newLine] , esi
        mov dword [backspace], edi
        mov eax, esp
        mov esp, ebp
        mov ebp, eax
        mov dword [esp], 0 ;eax
        mov dword [esp +4], 0 ;ebx
        mov dword [esp +8], 0xb8000 ;ecx
        mov dword [esp +12],0 ;edx
        call [setup_xy]
        mov ebx, Gdt_init
        mov eax, ram_detect - Gdt_init -1
        call [print_tty]
        call [newLine]
    ata_init:
        call 0x10ea00
        pop ecx
        pop ebx
        pop eax
        mov dword [write_lba_28], ecx
        mov dword [dest], ebx
        mov dword [read_lba_28], eax
    memory_init:
        call 0x10c400
        pop edi
        pop edx
        pop ecx
        pop eax
        pop ebx
        mov dword [dump_mem], eax
        mov dword [page_calc], ebx
        mov dword [Valloc], ecx
        mov dword [page_walk], edx
        mov dword [Vfree], edi
        mov eax, [0x504]
        call [bin_hex]
        mov eax, [0x500]
        call [bin_hex]
        mov ebx, ram_detect
        mov eax, offset_page - ram_detect -1
        call [print_tty]
        call [newLine]
    keyboard_init:
        mov ebx, 0x200000
        mov eax, 1
        call [Valloc]
        call 0x10ec00
        pop eax 
        pop ebx
        pop ecx
        mov dword [scancode], ecx
        mov dword [read_keyboard], eax
        mov dword [kb_offset], ebx
    cmd_init:
        mov eax, command_buffer
        mov ebx, esi_CB_stor
        mov edx, Dump_regs
        mov edi, kprint
        mov esi, knewline
        push esi
        push edi
        push edx
        push ebx
        push eax
        call 0x10ee00
        pop eax
        mov dword [cmd_handler], eax
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

            mov edi, 0x21
            mov eax, keyboard
            call make_idt_entry

            mov edi, 0x2E
            mov eax, ATA_Handler
            call make_idt_entry

            mov al, 0b11111000
            out 0x21, al
            mov al, 0b10111111 
            out 0xA1, al

;======KERNEL======  
    xor edi, edi
    mov ebx, 0xffff35 ;2B2E
    mov eax, [print_tty]
    call irq_timer
    lidt [idt_ptr]
    sti
    init_list: 
        mov ebx, 'NoMM'
        mov dword [debug_exit_code_var], ebx
        mov ebx, '0x10'
        mov dword [debug_source_var], ebx
        call debug_function
        call [newLine]
        ;int 0x01
    Kernel_loop:
        cmp byte [enter_press], 1
        je .handle_enter
        jmp Kernel_loop
            .handle_enter:
                cmp dword [esi_CB_stor], 0
                je return_reset_enter
                call [cmd_handler]
            return_reset_enter:
                mov byte [enter_press], 0
                mov edx, [kb_offset]
                mov dword [edx], 0
        jmp Kernel_loop
;0010ce5c

kprint:; first thing on the stack is the str_length,second is pointer to the string
    pop ebp
    pop eax
    pop ebx
    call [print_tty]
    call [newLine]
    push ebp
    ret

knewline:
    pop ebp
    pusha
    call [clear_screen]
    popa
    push ebp
    ret

    read_keyboard_kernel: ;you need to manually reset the counter after calling
            cmp byte [enter_press], 1
            je .skip
            mov edx, [kb_offset]
            mov ecx, [edx]
            cmp ecx, 0
            je .skip
            xor ebx, ebx
            xor eax, eax
            mov esi, [esi_CB_stor]
            .loop_read_keyboard:
                movzx eax, byte [kb_start + ebx]
                push ebx
                push ecx
                xor ebx, ebx
                mov edi, [scancode]
                movzx ebx, byte [edi +eax]
                cmp ebx, 0x1c
                je .enter_press_raiser
                cmp ebx, 0x0e ;backspace
                jne .nobackspace
                mov eax, 0
                call [backspace]
                jmp .return_subrt
                .nobackspace:
                    mov [command_buffer +esi], ebx
                    inc dword [esi_CB_stor]
                    ;mov dword [var1], 0x00
                    mov dword [var1], ebx
                    mov ebx, var1
                    mov eax, 0
                    call [print_tty]
                .return_subrt:
                    pop ecx
                    pop ebx
                    inc ebx
                    loop .loop_read_keyboard
            .skip:
                ret
            .enter_press_raiser:
                mov byte [enter_press],1 
                call [newLine]
                jmp .return_subrt

%include "debug.asm"    

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
        pusha
        cmp byte [kb_used], 1
        jne .skip
        call read_keyboard_kernel
        mov byte [kb_used], 0
        mov edx, [kb_offset]
        mov dword [edx], 0x00
        .skip:
        mov al, 0x20
        out 0x20, al
        popa
        iret

    keyboard:
        pusha 
        xor eax, eax
        call [read_keyboard]
        mov byte [kb_used], 1
        mov al, 0x20
        out 0x20, al
        popa
        iret

    ATA_Handler:
        pusha
        cmp byte [ata_flag], 2
        je read_ata
        jmp return_ata
        read_ata:
            mov eax, [dest]
            mov edi, [eax]
            mov dx, 0x1f0
            mov ecx, 256
            .read:
                in ax, dx
                stosw
                loop .read
                jmp return_ata
        
        return_ata:
            .wait_done:
                xor ax, ax
                mov dx, 0x1f7
                in ax, dx
                test ax, 0x80       ; BSY
                jnz .wait_done
            mov byte [ata_flag], 1
            mov al, 0x20
            out 0xA0, al
            out 0x20, al
            popa
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
%include "kernel_strings.asm"
;cmd 
            cmd_handler dd 0x00
;kb
            read_keyboard dd 0x00
            kb_offset dd 0x00
            kb_start equ 0x200000
            kb_used db 0x00
            var1 dd 0x00
            enter_press db 0x00
            scancode dd 0x00
            esi_CB_stor dd 0x00
            command_buffer:
                times 128 dd 0x00 ; 512 db
;ata    
            write_lba_28 dd 0x00
            dest dd 0x00
            read_lba_28 dd 0x00
            ata_flag db 0x00
;mmu
            Valloc dd 0x00
            Vfree dd 0x00
;debug      
            page_walk dd 0x00
            dump_mem dd 0x00
            page_calc dd 0x00
;vga driver
            irq_timer equ 0x10Cc00 
            print_xy dd 0x00
            print_tty dd 0x00
            setup_xy dd 0x00
            bin_hex dd 0x00
            newLine dd 0x00
            backspace dd 0x00
            clear_screen dd 0x00

times 50120 - ($ - $$) db 0xee