;THIS IS AN IRQ DRIVEN ROUTINE!!!!!
;we already pushes all regs, all we did to get here was `pusha, call keyboard_driver`
; has to set leds, get/set scancode, identify keyboard (too lazy to for now), set typematic rate and delay
; enable/disable scanning, and self tests
;dl table: 0= init, 1= check/work on one byte on the list
[org 0x1c8200]
[bits 32]

test eax, eax
jne init_keyboard
test dl, dl
je irq_routine
test dl, 0b00000001
jnz list
ret

list:
    xor cx, cx
    mov eax, 0x530
    check_command:
        xor dl, dl
        mov ebx, [eax]
        xor cx, cx
        test ebx, ebx
        jnz .exec_command
        add eax, 2
        cmp cx, 511
        jge .return
        jmp check_command

    .exec_command:
        mov edx, eax
        xor eax, eax
        mov ax, [edx]
        push ax
        mov al, 0x00
        mov byte [edx], al
        pop ax
        ;cmp al, 0x00 ; key detec err/int buff overrun
        ;je .key_dec_err
        ;cmp al, 0xff ; key detec err/int buff overrun
        ;je .key_dec_err
        cmp al, 0x80 ; key release
        je .return
        cmp al, 0xaa; selftest passed
        je .return
        cmp al, 0xfa ; command acknowledged
        je .ack ; returns rightnow
        cmp al, 0xfc ; selftest failed
        je .selftest_fail
        cmp al, 0xfd ; self test failed
        je .selftest_fail
        cmp al, 0xfe ; resend command
        je .resend ; returns rightnow
        ;if its none of these, its a keyboard input
        jmp translate_to_ascii

    .key_dec_err:
        push ebx
        mov ebx, key_dec
        mov ah, 0x0f
        mov dl, print_char | loop_func
        call print
        pop ebx
        jmp .return

    .ack: ; does nothing atm, maybe we'll do something with it later
        jmp .return

    .selftest_fail:
        push ebx
        mov ebx, Self_test_f
        mov ah, 0x0f
        mov dl, print_char | loop_func
        call print
        pop ebx
        jmp .return

    .resend: 
        jmp .return

    .return:
        xor eax, eax
        mov al, 0x00
        mov byte [edx], al
        ret

    translate_to_ascii:
        movzx bx, al
        mov edx, scancode_table
        add edx, ebx
        mov al, [edx]
        jmp compare_special_key

    compare_special_key:
        cmp al, 2
        je set_enter
        cmp al, 1
        je backspace
        cmp al, 0x20
        je print_keyboard
        cmp al, 0x00
        je backspace
        jmp print_keyboard


        print_keyboard:
            mov dl, print_char
            mov ah, 0x0f
            call print
            ret

        backspace:
            ret

        set_enter:
            ;mov dl, 0b00000010 ; enter key
            ret

irq_routine:
    xor cx, cx
    mov eax, 0x530

    space_check:
        mov edx, [eax]
        test edx, edx
        jz write_val
        inc cx
        add eax, 2
        cmp cx, 511
        jge full_list
        jmp space_check

    full_list:
        mov ebx, full
        xor eax, eax
        mov ah, 0x04
        mov dl, print_char | loop_func
        call print
        ret

    write_val:
        mov esi, eax
        in al, 0x60
        mov byte [esi], al
        cmp al, 0xe0
        jne .test_two
        .test_two:
            cmp al, 0xe1
            jne .return
        in al, 0x60
        mov byte [esi + 1], al
        ret

    .return:
        ret

init_keyboard:
    mov [exec_list], eax
    xor eax, eax
    mov ebx, loaded
    mov ah, 0x0f
    mov dl, print_char | loop_func
    call print
    xor eax, eax
    ret

full db '[E] List full! please try again later',0
loaded db 'Keyboard init',0
key_dec db '[E] Keyboard keydetection error! Please retry',0
Self_test_f db '[E] Keyboard self-test failed! Retrying...',0
empty db '[I] Nothing in the list!',0

exec_list db 0x00
        ;vga support
        print_char equ 0b00000001
        loop_func  equ 0b00000010
        res_scr    equ 0b00000100
        clr_scr    equ 0b00001000
        N_line     equ 0b00010000
        start_vga  equ 0b00100000
        print      equ 0x1c8000
;keyboard_dl_table
check_list equ 0b00000001
        scancode_table:

        times (128-48) db 0
times 1024 - ($ - $$) db 0x00
