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
        mov dword [LBA_address], 0x6f
        mov dword [dest], 0x100000
        mov byte [write_enable], 0
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

            mov edi, 0x21
            mov eax, keyboard
            call make_idt_entry

            mov edi, 0x2E
            mov eax, Disk_ATA_Handler
            call make_idt_entry

            ; Mask everything except IRQ0 (timer), for now
            mov al, 0b11111011
            out 0x21, al
            mov al, 0b10111111 
            out 0xA1, al

;======KERNEL======
    lidt [idt_ptr]
    sti
    int 0x01

    hechloopd:
        cmp byte [enter_en], 1
        je parsing_setup
        jmp hechloopd

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
            writeFS_Disk:
                xor ecx, ecx
                xor eax, eax
                xor bl, bl
                lea eax, [lookup_table]
                mov dword [dest], 0x100000
                call read_status
                call status_ch_busy
                cmp bl, 1
                je writeFS_Disk
                call status_ch_ready
                xor ecx, ecx
                call set_drive
                mov byte [write_enable], 1
                mov dword [LBA_address], 0x0b
                mov dword [sector], 1
                call set_lba
                call status_ch_busy
                cmp bl, 1
                je writeFS_Disk
                call set_RW
                hlt
                ret

            readFS_Disk:
                xor ecx, ecx
                xor eax, eax
                xor bl, bl
                lea eax, [lookup_table]
                mov dword [dest], 0x100000
                call read_status
                call status_ch_busy
                cmp bl, 1
                je readFS_Disk
                call status_ch_ready
                xor ecx, ecx
                call set_drive
                mov byte [write_enable], 0
                mov dword [LBA_address], 0x0b ;0x6F
                mov dword [sector], 1
                call set_lba
                call status_ch_busy
                cmp bl, 1
                je readFS_Disk
                call set_RW
                hlt
                ret


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
                call readFS_Disk
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
            jmp hechloopd
        
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

        keyboard:
            pusha
            in al, 0x60             ; Read scancode
            cmp al, 0x80
            jae key_release        ; Ignore key releases

            ; Translate scancode to ASCII
            movzx bx, al
            mov edx, scancode_table
            add edx, ebx
            mov al, [edx]
            mov edi, [CMD_string]
            ;mov esi, [buffer_ptr]
            mov ecx, [vid_counter]


            ;check if its the enter key
            cmp al, 2
            je set_enter
            cmp al, 1
            je backspace
            jmp print_keyboard

            backspace:
                cmp esi, 0xb8000
                jbe key_release
                cmp ecx, 0
                jbe esi_sub
                dec ecx
                cmp edi, 0x530
                jbe esi_sub
                mov byte [edi], ' '
                dec edi
                esi_sub:
                    mov word [esi], ' '
                    sub esi, 2
                    mov word [esi], ' '
                    ;mov [buffer_ptr], esi
                    mov [CMD_string], edi
                    mov [vid_counter], ecx
                    jmp key_release
            
            set_enter:
                mov byte [enter_en], 1
                jmp key_release


            ; Print character at video memory pointed by ESI and puts it in a string holder
            print_keyboard:
                inc ecx
                mov [vid_counter], ecx
                mov byte [edi], al
                inc edi
                mov [CMD_string], edi
                mov ah, 0x0F
                mov word [esi], ax
                add esi, 2
                ;mov [buffer_ptr], esi
                cmp esi, 0xB8F9E        ; Screen end? Reset cursor
                jae reset_cursor

            key_release:
                mov al, 0x20
                out 0x20, al            ; EOI PIC
                popa
                iret

            reset_cursor:
                mov esi, 0xB8000
                ;mov [buffer_ptr], esi
                jmp key_release        ; EOI and return

        Disk_ATA_Handler:
            pusha
            mov cx, 256
            mov dx, ATA_IO_Base
            cmp byte [write_enable], 1
            je .write
            jmp .read
            .read:
                cld
                mov di, [dest]
                rep insw
                mov [dest], di
                jmp .done

            .write:
                mov si, [dest]
                .loop:
                    outsw
                    add si, 2
                    jmp $ + 2
                    loop .loop
                mov [dest], si
                mov dx, ATA_IO_Base + 7
                mov al, 0xe7
                out dx, al
                jmp .done

            .done:
                mov al, 0x20
                out 0x20, al            ; EOI PIC
                out 0xA0, al         ; send EOI to slave PIC
                popa
                iret

write_file_info:
    mov dword [read_loc], eax
    mov dword [read_loc +4], ecx
    mov byte [read_loc +8], bl
    ret

; \\setup_drive//
    set_drive: ;cl =0 master, 1=slave
        mov eax, [LBA_address]
        shr eax, 28 ;shr by lba-N (n=4)
        and eax, 0x0f ; mask only the lowest 4 bits
        cmp cl, 0
        je set_master
        or al, 0xf0 ; or it with 0xf0 for 'slave'
        jmp send_port_1f6

        set_master:
            or al, 0xe0 ; or it with 0xe0 for master bit

        send_port_1f6:
            mov dx, ATA_IO_Base + 6 ; 0x1f6
            out dx, al
            ret

    set_lba: ; also sets sector count!
        set_sector:
            mov al, [sector]
            mov dx, ATA_IO_Base + 2 ;base is 0x1f0, plus two makes 0x1f2
            out dx, al
        
        set_lowbyte:
            mov eax, [LBA_address]
            mov dx, ATA_IO_Base + 3
            out dx, al

        set_midbyte:
            mov al, ah
            mov dx, ATA_IO_Base + 4
            out dx, al

        set_highbyte:
            shr eax, 16
            mov dx, ATA_IO_Base + 5
            out dx, al
            ret

    set_RW: ; expects write_enable = 1 when it wants to read
        cmp byte [write_enable], 1
        je .write
        mov al, 0x20
        jmp send_port_1f7

        .write:
            mov al, 0x30
        
        send_port_1f7:
            mov dx, ATA_IO_Base + 7
            out dx, al
            ret

; \\error_handling//
    check_status: ; sets ch if there was a problem, bh = data ready (incase we missed), bl= busy, try later
        read_status:
            mov dx, ATA_IO_Base +7
            in al, dx
            mov [status], al
            ret

        status_ch_error: 
            mov al, [status]
            test al, err
            jz ret_disk
            call reset_drive
            mov ch, 1
            jmp ret_disk
            
        status_ch_index:
            mov al, [status]
            test al, idx
            jz ret_disk
            call reset_drive
            mov ch, 1
            jmp ret_disk
        
        status_ch_corrected_data:
            mov al, [status]
            test al, corr
            jz ret_disk
            call reset_drive
            mov ch, 1
            jmp ret_disk
            
        status_ch_DRQ:
            mov al, [status]
            test al, drq
            jz ret_disk
            mov bh, 1
            jmp ret_disk
        
        status_ch_SRV:
            mov al, [status]
            test al, srv
            jz ret_disk
            mov bl, 1
            jmp ret_disk

        status_ch_drive_fault:
            mov al, [status]
            test al, Df
            jz ret_disk
            call reset_drive
            mov ch, 1
            jmp ret_disk

        status_ch_ready:
            mov al, [status]
            test al, rdy
            jnz ret_disk
            jmp status_ch_ready ; we want to loop this until ready. no polling
        
        status_ch_busy: ;we want to check this every so often
            mov al, [status]
            test al, bsy
            jz ret_disk
            mov bl, 1
            jmp ret_disk
        
        ret_disk:
            ret

    reset_drive:
        mov dx, 0x3f6 ; control reg, we want to send nIEN so that we dont get yelled at by IRQs
        mov al, 0x06
        out dx, al ; send mass reset of every drive on the bus :troll:
        mov cx, 10
        mov dx, ATA_IO_Base +7
        delay_5us_ata:
            in al, dx
            in al, dx
            in al, dx
            in al, dx
            loop delay_5us_ata
        mov al, 0x00 ;set the others to empty
        mov dx, 0x3f6
        out dx, al
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
    Gdt_init db 'gdt init',0
    Idt_init db 'idt init',0
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
        print equ 0x1c8000
    vid_counter dd 0 ;keyboard
    CMD_string dd 0x530
    cursor_timer db 10               ; countdown timer (ticks before toggle)
    cursor_vis   db 1                ; cursor visible flag (1=visible, 0=invisible)
    enter_en equ 0x500 ; 1= enter was pressed
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
        db "memm"

        times 512 - 8 db 0
    file_table:
        dd 0x0000007E
        dd 0x00000001
        db 0b00111001
        
        times 4608 - 9 db 0 ; exactly 9 times 512 bytes
times 51200 - ($ - $$) db 0xff
