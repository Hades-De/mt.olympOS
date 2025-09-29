;expects ebx to have a string if it needs to print. then also dl=00000011 (print, loop on)
;dl table    00000001 print single char,  00000010 loop current set for cx times(not for printing strings, that expects ebx to be set), 00000100 reset screen pointer, 00001000 clear screen
;dl table    00010000 new line ,00100000 ????,01000000 ???,10000000 ?????
;add full scrolling screen
[org 0x1C8000]
[bits 32]
sort_dl:
    mov esi, [current_loc_vid]
    mov edi, [line_ctr]
    test dl, print_char
    jnz Print_Character
    test dl, N_line
    jnz Next_line
    test dl, clr_scr
    jnz clear_screen
    test dl, start_vga 
    jnz set_VGA
    call no_vga
    
    set_VGA:
        mov esi, 0xb8000
        mov [current_loc_vid], esi
        xor dl, dl 
        ret
    
    Print_Character: ;resets eax, edi, esi, and dl and ebx when looping
        test dl, loop_func
        jnz .loop_char
        .print_char_start:
            mov esi, [current_loc_vid]
            mov edi, [line_ctr]
            .space_detect:
                cmp al, space
                jne .print
                mov al, 0x00
                .print:
                    mov word [esi], ax
                    add esi, 2
                    cmp esi, vidmemend
                    jae .set_reset_curs
                    .update_print_ptr:
                        inc edi
                        cmp edi, 80
                        je .set_reset_crt
                    .return:
                        mov [current_loc_vid], esi
                        mov [line_ctr], edi
                        xor dl, dl
                        ret
                    .set_reset_crt:
                        mov edi, 0
                        jmp .return
                    .set_reset_curs:
                        xor dl, dl
                        mov dl, res_scr
                        jmp sort_dl
                    .loop_char:
                        mov al, [ebx]
                        test al, al
                        je .return
                        call .print_char_start
                        inc ebx
                        jmp .loop_char

    Next_line: ;resets eax, edi, esi and resets dl
        cmp edi, 80
        jge .return
        xor ax, ax
        inc edi
        mov word [esi], ax
        add esi, 2
        cmp esi, vidmemend
        jae .set_reset_curs
        jmp Next_line
        .set_reset_curs:
            xor dl, dl
            mov dl, res_scr
            jmp sort_dl
        .return:
            xor edi, edi
            mov [current_loc_vid], esi
            mov [line_ctr], edi
            xor dl, dl
            ret

    clear_screen: ; uses eax, ecx, esi, resets dl
        xor ax, ax
        xor dx, dx
        mov esi, 0xB8000
            .clear:
                mov word [esi], ax
                add esi, 2
                inc dx
                cmp dx, 1967
                jl .clear
                mov esi, 0xB8000
                mov [current_loc_vid], esi
                xor dl, dl
                ret

    no_vga: 
        mov ebx, Vga_invalid
        mov ah, 0x0f
        mov dl, loop_func
        call Print_Character
        xor dl, dl
        ret

Vga_invalid db 'No VGA code found',0   
color_ar_buffr db 0
line_ctr dd 0
vidmemend equ 0xB8F9E
current_loc_vid dd 0xB8000
space equ 0x20
print_char equ 0b00000001
loop_func  equ 0b00000010
res_scr    equ 0b00000100
clr_scr    equ 0b00001000
N_line     equ 0b00010000
start_vga  equ 0b00100000
;NaN equ 0b01000000
;NaN  equ 0b10000000

times 512 - ($ - $$) db 0