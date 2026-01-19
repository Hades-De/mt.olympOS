[org 0x10D600]
[bits 32] 
;edi tests
edi_tests:
    test edi, init
    jnz init_lib
    test edi, print_str
    jnz prnt_str
    ret


init_lib:
    mov dword [vga_buffer], 0xb8000
    xor edi, edi
    mov ebx, init_done
    mov ax, text_end - init_done
    shl eax, 16
    mov ah, 75
    mov al, 24
    mov edi, print_str
    jmp edi_tests

prnt_str: ;how to make the call; ebx= pointer to the string loc. eax high 16 bit = length ah = Xposition, al = YPosition (pos are starting at 0)
    calculate_offset:
        mov [Xpos], ah ;store wanted X pos
        mov [Ypos], al ;store wanted Y pos
        cmp byte [Xpos], Xmax ;compare if its not overflowing
        jg .Invalid_pos
        cmp byte [Ypos], Ymax
        jg .Invalid_pos
        shr eax, 16 ;now get the string length
        mov [length], ax ;store it
        xor eax, eax
        mov al, [Ypos] ; now we calculate the offset (where we need to start putting the string)
        mov ecx, Xmax ; the math goes like this ecx= max X lines ((Ypos*ecx)+Xpos)*2 = total offset
        mul ecx ;Ypos*ecx = V
        xor ecx, ecx
        mov cl, [Xpos]
        add eax, ecx ;V+Xpos=W
        mov ecx, 2
        mul ecx ;W*2=Q 
        mov ecx, [vga_buffer]
        add eax, ecx ;Q+buffer= actual location to plot
        mov esi, eax ;finally move the end location to a variable so we can run functions with it
        xor ecx, ecx
        mov edx, [vga_buffer]
        add edx, 4000
    .print:
        cmp dword [length], ecx
        jl .done
        mov ah, 0x0f
        mov al, [ebx + ecx]
        mov word [esi + ecx*2], ax
        inc ecx
        lea eax, [esi + ecx*2]
        cmp eax, edx
        jge .Invalid_pos
        jmp .print
        .done:
            xor edi, edi
            ret

    .Invalid_pos:
        xor eax, eax
        mov ebx, invalid_location
        mov ax, init_done - invalid_location -1
        shl eax, 16
        xor ax, ax ; since that would be 0,0
        jmp calculate_offset




;texts
    invalid_location db "invalid VGA location, try again"
    init_done db "init done, allocated the VGA buffer"
    text_end db 0x00

;variables
    vga_buffer dd 0x00 
    Xpos db 0x00
    Ypos db 0x00
    Xmax equ 80
    Ymax equ 25
    length dd 0x00


;edi table


    ;video first 8bytes
        init       equ 0b00000000000000000000000000000000001 ;location info in ecx
        print_str  equ 0b00000000000000000000000000000000010
        res_scr    equ 0b00000000000000000000000000000000100
        clr_scr    equ 0b00000000000000000000000000000001000
        N_line     equ 0b00000000000000000000000000000010000
        get_loc    equ 0b00000000000000000000000000000100000
        ;nan       equ 0b00000000000000000000000000001000000
        ;NaN       equ 0b00000000000000000000000000010000000


    ;base convetion
        hex_dec    equ 0b00000000000000000000000000100000000
        dec_hex    equ 0b00000000000000000000000001000000000
        bin_hex    equ 0b00000000000000000000000010000000000
        hex_bin    equ 0b00000000000000000000000100000000000
        bin_dec    equ 0b00000000000000000000001000000000000
        dec_bin    equ 0b00000000000000000000010000000000000
        ;NaN       equ 0b00000000000000000000100000000000000
        ;NaN       equ 0b00000000000000000001000000000000000

times 512 - ($ - $$) db 0