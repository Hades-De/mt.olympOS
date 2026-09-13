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
    NCM db "No command found!"
    text_end db 0x00

;debug
    debug_type_const db 'type '
    debug_exit_code_const db 'exit code '
    debug_source_const db 'source pos '
    debug_registerdump_const db "reg dump"
    text_debug_end db 0x00

    debug_type_var dd 0x00
    debug_exit_code_var dd 0x00
    debug_source_var dd 0x00
    debug_ret_header_test dd 0x00
    dd 0x00