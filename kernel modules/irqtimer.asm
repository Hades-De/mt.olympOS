        timer:
            pusha
            ;keyboard_timer:
                ;mov esi, [buffer_ptr]        ; video memory ptr (cursor location)     
                mov al, [cursor_timer]
                dec al
                mov [cursor_timer], al
                cmp al, 0
                jne .skip_toggle             ; if timer not zero, skip toggle
                ; Timer hit zero, toggle cursor visibility
                mov al, [cursor_vis]
                xor al, 1                   ; flip 1 -> 0 or 0 -> 1
                mov [cursor_vis], al
                ; Reset countdown timer to 10 (arbitrary blink speed)
                mov byte [cursor_timer], 10
                .skip_toggle:
                    ; Write cursor character or clear it depending on cursor_vis
                    mov al, [cursor_vis]
                    cmp al, 1
                    jne .hide_cursor

                    ; Cursor ON: print underscore 0x5F with attribute 0x0F
                    mov ax, 0x0F5F              ; 0x0F attribute + 0x5F underscore
                    mov word [esi], ax
                    jmp .done

                .hide_cursor:
                    ; Cursor OFF: clear the character (space with attribute 0x07)
                    mov ax, 0x0720              ; normal gray space
                    mov word [esi], ax

                .done:
                    ; Send EOI to PIC and exit
                    mov al, 0x20
                    out 0x20, al
                    popa
                    iret


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
    status db 0
    LBA_address dd 0x6f
    ATA_IO_Base equ 0x1f0  
    sector db 0            
    write_enable db 0
    dest dd 0
    err  equ 0b00000001
    idx  equ 0b00000010
    corr equ 0b00000100
    drq  equ 0b00001000
    srv  equ 0b00010000
    Df   equ 0b00100000
    rdy  equ 0b01000000
    bsy  equ 0b10000000
    ;vga driver
        print_char equ 0b00000001
        loop_func  equ 0b00000010
        res_scr    equ 0b00000100
        clr_scr    equ 0b00001000
        N_line     equ 0b00010000
        start_vga  equ 0b00100000
        print      equ 0x1c8000
    vid_counter dd 0 ;keyboard
    CMD_string dd 0x530
    cursor_timer db 10               ; countdown timer (ticks before toggle)
    cursor_vis   db 1                ; cursor visible flag (1=visible, 0=invisible)
    enter_en equ 0x500 ; 1= enter was pressed
    ;keyboard driver
        exec_list:
            times 1028 db 0x00
        
        keyboard_driver equ 0x1c8200
        command_key dd 0
    commands_len_2:
        dd 'ls','cd',0, 0
    commands_len_3:
        dd 'clr', 0
    commands_len_4:
        db 'echo', 'ping','help','load', 0
        ;dd cd
    scancode_table:
        db '#','$','1','2','3','4','5','6','7','8','9','0','-','=',1,'@'
        db 'q','w','e','r','t','y','u','i','o','p',"[","]",2,'^','a','s','d','f'
        db 'g','h','j','k','l',';',0,0,0,'/','z','x','c','v','b','n','m',',','.','\',0,0,0,0x20
        times (128-48) db 0
    read_loc dd 0
    lookup_table:
        db "mem "
        db "vga "
        db "kbd "
        times 512 - 12 db 0
    file_table:
        dd 0x0000007E
        dd 0x00000001
        db 0b00111001
        dd 0x0000006F
        dd 0x00000001
        db 0b00111101
        dd 0x00000070
        dd 0x00000001
        db 0b00111101

        
        times 4608 - 27 db 0 ; exactly 9 times 512 bytes