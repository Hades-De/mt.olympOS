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

Dump_page_info:; expects eax to hold the Vmem loc
        call [page_calc]
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

Dump_mem_walk: ; shows the location of each page part
        mov ebx, eax
        call [page_walk]
        pop eax
        call [bin_hex]
        mov ebx, pde
        mov eax, space - pde -1
        call [print_tty]
        pop eax
        and eax, 0xFFFFF000
        call [bin_hex]
        mov ebx, pte
        mov eax, pde - pte -1
        call [print_tty]
        pop eax
        and eax, 0xFFFFF000
        call [bin_hex]
        ret

debug_function:
        ;save the ret pointer
        pop ebp
        mov dword [debug_ret_header_test], ebp
        call [clear_screen]

        debug_type_print:
                mov ebx, debug_type_const
                mov ax, debug_exit_code_const - debug_type_const -1
                shl eax, 16
                call [print_xy]
                ;now the var
                mov ebx, debug_type_var
                mov ax, debug_exit_code_var - debug_type_var -1
                shl eax, 16
                mov ah, debug_exit_code_const - debug_type_const
                xor al, al
                call [print_xy]

        check_type:
                mov ebx, [debug_type_var]
                cmp ebx, 0x60
                jge skip_error_type_var
                cmp ebx, 0x50
                jge t50_type
                cmp ebx, 0x40
                jge t40_type
                cmp ebx, 0x30
                jge t30_type
                cmp ebx, 0x20
                jge t20_type
                cmp ebx, 0x10
                jge t10_type
                jmp t00_type

        exit_code_print: ;we assume its a call
                pop ebp
                mov ebx, debug_exit_code_const
                mov ax, debug_source_const - debug_exit_code_const -1
                shl eax, 16
                mov al, 1
                call [print_xy]
                ;now the variable
                mov ebx, debug_exit_code_var
                mov ax, debug_source_var - debug_exit_code_var -1
                shl eax, 16
                mov ah, debug_source_const - debug_exit_code_const
                mov al, 1
                call [print_xy]
                push ebp
                ret
        
        source_print:
                pop ebp
                mov ebx, debug_source_const
                mov ax, debug_registerdump_const - debug_source_const -1
                shl eax, 16
                mov al, 2
                call [print_xy]
                ;now the variable
                mov ebx, debug_source_var
                mov ax, debug_ret_header_test - debug_source_var - 1
                shl eax, 16
                mov ah, debug_registerdump_const - debug_source_const
                mov al, 2
                call [print_xy]
                push ebp
                ret
        
        reg_dump_print:
                pop ebp
                mov dword [debug_ret_header_test+4], ebp
                mov ebx, debug_registerdump_const
                mov ax, text_debug_end - debug_registerdump_const -1
                shl eax, 16
                mov al, 3
                call [print_xy]
                ;now we dump the regs
                pusha
                call [newLine]
                call [newLine]
                call [newLine]
                call Dump_regs
                mov ebp, [debug_ret_header_test+4]
                push ebp
                ret
        
        t00_type:
                call exit_code_print
                call source_print
                call reg_dump_print
                jmp return_debug
        
        t10_type:
                jmp t00_type
        
        t20_type:
                jmp t00_type
                
        t30_type:
                jmp t00_type

        t40_type:
                jmp t00_type

        t50_type:
                jmp t00_type

        skip_error_type_var:
                jmp return_debug
        
        
        return_debug:
                mov dword [debug_type_var],0
                mov dword [debug_source_var],0
                mov dword [debug_exit_code_var],0
                ;return the ret pointer
                mov ebp, [debug_ret_header_test]
                push ebp
                ret