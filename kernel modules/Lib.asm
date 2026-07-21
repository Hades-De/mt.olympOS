[org 0x10c800]
[bits 32] 
jmp init_lib

init_lib: ;returns all the locations on the stack
    pop edx
    mov eax, prnt_str
    mov ebx, setup_xy
    mov ecx, print_tty
    mov esi, binary_hex
    mov edi, new_line
    push edi
    push esi
    push eax
    push ebx
    push ecx
    push edx
    ret

setup_xy: ; ecx holds the buffer loc, edx vga mode 1=non 80x25 mode, low eax holds xpos, high eax holds ypos. ebx holds col bit info
    mov dword [vga_buffer], 0xb8000
    mov dword [tty_offset], 160
    xor edx, edx
    cmp edx, 0
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
        mov ax, text_end - init_done
        shl eax, 16
        mov ah, 0
        mov al, 0
        call prnt_str
        ret

prnt_str: ;how to make the call; ebx= pointer to the string loc. eax high 16 bit = length ah = Xposition, al = YPosition (pos are starting at 0)
    calculate_offset:
        xor ecx, ecx
        cmp ah, [Xmax] ;compare if its not overflowing
        jg Invalid_pos
        mov ch, ah
        cmp al, [Ymax]
        jg Invalid_pos
        mov dl, al
        shr eax, 16 ;now get the string length
        mov [length], ax ;store it
        xor eax, eax
        mov al, dl ; now we calculate the offset (where we need to start putting the string)
        mov cl, [Xmax] ; the math goes like this ecx= max X lines ((Ypos*ecx)+Xpos)*2 = total offset
        mul cl ;Ypos*ecx = V
        mov cl, ch
        xor ch, ch
        add eax, ecx ;V+Xpos=W
        shl eax, 1
        mov ecx, [vga_buffer]
        add eax, ecx ;Q+buffer= actual location to plot
        mov esi, eax ;finally move the end location to a variable so we can run functions with it
        mov edx, [vga_buffer]
        add edx, [max_size]
        xor ecx, ecx
    print: ;perhaps add a edi for number printing at the end (hex), actually, i already have the string length, i can just glue it after
        cmp dword [length], ecx
        jl .done
        mov ah, 0x0f
        mov al, [ebx + ecx]
        mov word [esi + ecx*2], ax
        inc ecx
        lea eax, [esi + ecx*2]
        cmp eax, edx
        jge Invalid_pos
        jmp print
        .done:
            mov dword [length], 0
            xor edi, edi
            ret
    Invalid_pos:
        mov ebx, invalid_location
        mov ax, init_done - invalid_location -1
        shl eax, 16
        xor ax, ax ; since that would be 0,0
        jmp calculate_offset

print_tty: ;prints to the screen using tty. ebx string loc, and eax string length
    mov edx, [vga_buffer]
    add edx, [max_size]
    mov [length], eax  
    inc eax
    mov ecx, [tty_offset]
    add ecx, eax 
    cmp ecx, [max_size] ;checks if it overextends
    jge .reset_tty
    mov esi, [vga_buffer]
    add esi, [tty_offset]
    shl eax, 1
    add dword [tty_offset], eax
    mov ecx, [tty_offset]
    xor ecx, ecx
    call print
    ret
    .reset_tty:
        mov dword [tty_offset], 0
        jmp print_tty

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