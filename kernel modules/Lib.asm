[org 0x10c800]
[bits 32] 

init_lib: ;returns all the locations on the stack
    mov eax, esp ;temp save the current stack to eax
    mov esp, ebp ; get the var stack to the pos
    mov ebp, eax ;save the 'old' stack to ebp
    .disable_csr:
        mov dx, 0x3D4
        mov al, 0x0A
        out dx, al
        mov dx, 0x3D5
        mov al, 0x20
        out dx, al
    mov eax, print_xy
    mov ebx, setup_xy
    mov ecx, print_tty
    mov edx, binary_hex
    mov esi, new_line
    mov edi, backspace
    pusha
    mov eax, clear_screen
    push eax
    mov eax, esp
    mov esp, ebp
    mov ebp, eax
    ret

setup_xy: ; ecx holds the buffer loc, edx vga mode 1=non 80x25 mode, low eax holds xpos, high eax holds ypos. ebx holds col bit info
    mov eax, [esp+4]
    mov ebx, [esp+8]
    mov ecx, [esp+12]
    mov edx, [esp+16]
    mov dword [vga_buffer], ecx
    mov dword [tty_offset], 0
    cmp dx, 0
    je .setup_default ;sets the default 80*25 mode
    mov [Xmax], ax 
    shr eax, 16
    mov [Ymax], ax
    mul byte [Xmax] ; multiplies vertical by horizontal, then by two cause of color byte
    add eax, eax
    mov [max_size], eax
    jmp .continue_init
    ;add something to do color defining
    .setup_default:
        mov byte [Ymax], 25
        mov byte [Xmax], 80
        mov word [max_size], 4000
    .continue_init:
        mov ecx, [max_size]
        xor ax, ax
        mov edi, [vga_buffer]
        rep stosw
        mov ebx, init_done
        mov eax, text_end - init_done -1
        call print_tty
        ret

print_xy: ;how to make the call; ebx= pointer to the string loc. eax high 16 bit = length ah = Xposition, al = YPosition (pos are starting at 0)
    check_valid_pos:;leave ebx be for the print call
        mov ecx, eax
        mov edx, eax
        shr ecx, 16; get length
        inc ecx
        add ah, cl
        check_x:
            cmp ah, [Xmax] ; if its >= then we subtract 80, check again and add one to al
            jae Y_inc
        check_y:
            cmp al, [Ymax] ; if its > then we wrap it around to 0, x. 
            jg reset_tty
        sub ah, cl ; return the original adress
        jmp calculate_offset_xy
        Y_inc:
            sub ah, [Xmax]
            inc al
            jmp check_x
        reset_tty:
            mov al, 0
            jmp check_y
    
    calculate_offset_xy:
        xor eax, eax
        mov al, dl
        movzx edi, byte [Xmax]
        push edx
        mul edi
        pop edx
        shr dx, 8
        add ax, dx
        shl eax, 1
        mov esi, [vga_buffer]
        add esi, eax
    ;now esi has the location, ebx still has the string, and ecx still has the string length
        jmp print
     
    print: ;ecx =total length, ebx = string location, esi contains the location of the xy or tty, caller is expected to set these
        xor edx, edx
        .loop_print:
            mov ah, 0x0f
            mov al, [ebx + edx]
            mov word [esi + edx*2], ax
            inc edx
            loop .loop_print
            ret

print_tty: ;prints to the screen using tty. ebx string loc, and eax string length
    inc eax
    mov ecx, eax
    shl eax, 1
    ;ebx and ecx are set now, so dont touch
    set_compare_esi:
        mov edi, [vga_buffer]
        add edi, [max_size]
        mov esi, [vga_buffer]
        add esi, [tty_offset]
        add esi, eax
        cmp esi, edi
        jg .reset_tty
        sub esi, eax
        add dword [tty_offset], eax
    ;now that we set and compared esi to make sure its safe, lets print it
    jmp print
    .reset_tty:
        mov dword [tty_offset], 0
        jmp set_compare_esi

backspace:
    cmp dword [tty_offset], 0
    je .done
    sub dword [tty_offset], 2
    mov esi, [vga_buffer]
    add esi, [tty_offset]
    mov ax, 0x0000     ; white space
    mov [esi], ax
    .done:
        ret

clear_screen:
    mov ecx, [max_size]
    xor ax, ax
    mov edi, [vga_buffer]
    rep stosb
    mov dword [tty_offset], 0
    ret

new_line:
    xor ecx, ecx
    mov eax, [tty_offset]
    shr eax, 1
    xor edx, edx
    mov cl, [Xmax]
    div ecx
    sub ecx, edx
    shl ecx, 1
    add dword [tty_offset], ecx
    ret


binary_hex: 
    xor edx, edx
    mov esi, eax
    .loop:
        xor ecx, ecx
        and al, 0x0f
        movzx ebx, al
        mov cl, [Hex_list +ebx]
        neg edx
        mov [bases_print + edx +7], cl
        neg edx
        mov eax, esi
        inc edx 
        mov ecx, edx
        shl ecx, 2
        shr eax, cl
        cmp edx, 7
        jle .loop
    .exit_loop: 
        xor eax, eax
        mov ebx, bases_print
        mov ax, dx 
        dec ax
        call print_tty
        ret

;texts
    bases_print:
        times (16) db 0x00 ;we have 64 bytes of printing numbers
    invalid_location db "invalid VGA loc"
    init_done db "[OK] Lib init"
    text_end db 0x00

;variables
    ;video stream variables
        tty_offset dd 0x00
        vga_buffer dd 0x00 
        Xmax db 0x00
        Ymax db 0x00
        length dd 0x00
        max_size dd 0x00
    ;base convertion
        low_nib db 0x00
        numb db 0x00
    ;bases
        Hex_list db '0123456789ABCDEF'
    ;to do, base convetion
        ;hex_dec
        ;dec_hex
        ;hex_bin
        ;bin_dec
        ;dec_bin


times 1024 - ($ - $$) db 0