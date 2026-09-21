pusha
;maybe check if it isnt more then 0xfe orso
jmp [handler +eax*4]

tty_print:
    mov eax, ecx
    call [print_tty]
    jmp return_int_80

xy_print:
    mov eax, ecx
    call [print_xy]
    jmp return_int_80

new_line_print:
    call [newLine]
    jmp return_int_80

reg_to_display_print:
    mov eax, ebx
    call [bin_hex]
    jmp return_int_80

clear_screen_print:
    call [clear_screen]
    jmp return_int_80

backspace_print:
    call [backspace]
    jmp return_int_80

dump_regs_debug:
    pusha
    call Dump_regs
    jmp return_int_80

page_info_debug:
    mov eax, ebx
    call Dump_page_info
    jmp return_int_80

dump_mem_debug:
    mov eax, ebx
    call Dump_mem_loc
    jmp return_int_80

page_regs_debug:
    mov eax, ebx
    call Dump_mem_walk
    jmp return_int_80

write_ata:
    mov eax, ecx
    mov edi, edx
    call [write_lba_28]
    jmp return_int_80

read_ata_ata:
    mov eax, ecx
    mov edi, edx
    call [read_lba_28]
    jmp return_int_80  

valloc_mmu:
    mov eax, ecx
    call [Valloc]
    jmp return_int_80

vfree_mmu:
    mov eax, ecx
    call [Vfree]
    jmp return_int_80
return_int_80:
    popa
    iret
handler:
    dd tty_print
    dd xy_print
    dd new_line_print
    dd reg_to_display_print
    dd clear_screen_print
    dd backspace_print
    dd dump_regs_debug
    dd page_info_debug
    dd dump_mem_debug
    dd page_regs_debug
    dd write_ata
    dd read_ata
    dd valloc_mmu
    dd vfree_mmu


;functions
    ;screen 0-5
        sys_print_tty equ 0x00
        sys_print_xy equ 0x01
        sys_print_new_line equ 0x02
        sys_print_reg_2_display equ 0x03
        sys_print_clear_screen equ 0x04
        sys_print_backspace equ 0x05
    ;debug 6-9
        sys_debug_regs equ 0x06
        sys_debug_page_info equ 0x07
        sys_debug_dump_mem equ 0x08
        sys_debug_page_regs equ 0x09
    ;ata a-b
        sys_ata_write equ 0x0a
        sys_ata_read equ 0x0b
    ;mmu c-d
        sys_mmu_valloc equ 0x0c
        sys_mmu_vfree equ 0x0d