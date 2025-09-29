    parsing_setup:
        mov dl, N_line
        call print
        parsing:
            xor ecx, ecx
            mov edi, 0x530 ;start of the keyboard buffer
            mov al, [edi +2] ;checks the location of the start of the buffer +2, thus if any2 char command, it leaves the top two empty, we check that
            test al, al
            je two_byte_command
            mov al, [edi +3]
            test al, al
            je three_byte_command

        four_byte_command:
            mov dx, 4
            mov ebx, commands_len_4
            mov eax, [ebx + ecx*4]
            cmp dword eax, [edi]
            je command_found
            test eax, eax
            je command_not_found
            inc ecx
            jmp four_byte_command

        three_byte_command:
            mov dx, 3
            mov ebx, commands_len_3
            mov eax, [ebx + ecx*4]
            cmp dword eax, [edi]
            je command_found
            test eax, eax
            je command_not_found
            inc ecx
            jmp three_byte_command

        two_byte_command:
            mov dx, 2
            mov ebx, commands_len_2
            mov eax, [ebx + ecx*4]
            cmp dword eax, [edi]
            je command_found
            test eax, eax
            je command_not_found
            inc ecx
            jmp two_byte_command

         command_found:
            cmp dx, 3
            jl .handler2
            je .handler3
            jg .handler4
            jmp command_not_found ;if it somehow doesnt work, we just say we couldn't find the command

        ;======handlers======
            .handler4:
                mov eax, [handler_table4 + ecx*4]
                jmp eax
            .handler3:
                mov eax, [handler_table3 + ecx*4]
                jmp eax
            .handler2:
                mov eax, [handler_table2 + ecx*4]
                jmp eax

        functions:


            clear_buffer:
                mov byte [edi], 0x00
                dec edi
                cmp edi, 0x530
                ja clear_buffer
                ret
        ;======3-4 letter commands======
            echo:
                xor ebx, ebx
                add edi, 5
                mov ebx, edi
                mov ah, 0x0f
                mov dl, print_char | loop_func
                call print
                jmp command_done

            ping:
                jmp command_done

            help:
                mov ebx, commands_len_2
                mov ah, 0x0f
                mov dl, print_char | loop_func
                call print
                mov ax, ' '
                mov dl, print_char
                call print
                mov ebx, commands_len_3
                mov ah, 0x0f
                mov dl, print_char | loop_func
                call print
                mov ax, ' '
                mov dl, print_char
                call print
                mov ebx, commands_len_4
                mov ah, 0x0f
                mov dl, print_char | loop_func
                call print
                jmp command_done

            clear:  
                mov dl, clr_scr
                call print
                jmp command_done

            load:
                jmp command_done
                add edi, 5
                ;call Name_to_Loc ;when it returns, we have eax for the lba adress, and ecx, as the length in 512 sectors (1=512 bytes)
                mov [sector], ecx
                mov [LBA_address], eax
                ;call find_free_adress ;we'd want to write it to a free (non used) adress in memory

                ;call load_LBA

        ;======1-2 letter commands======
            ls:
                xor ebx, ebx
                xor eax, eax
                mov ebx, lookup_table
                mov ah, 0x0f
                mov dl, print_char | loop_func
                call print
                jmp command_done


        command_not_found:
            mov ebx, noCom
            mov ah, 0x0f
            mov dl, print_char | loop_func
            call print
        command_done:
            mov dl, N_line
            call print
            mov edi, 0x7000
            call clear_buffer
            mov edi, 0x530
            mov [CMD_string], edi
            mov byte [enter_en], 0
            ;jmp main kernel loop


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
    handler_table4:
        dd echo
        dd ping
        dd help
        dd load
        ;dd make
    handler_table3:
        dd clear
    handler_table2:
        dd ls
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