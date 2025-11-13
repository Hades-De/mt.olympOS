[org 0x10ce00]
[bits 32]
;gives a blinking time for the cursor
;gives a timer for the priobased Round Robin scheduler
timer_decoder:
    mov [usage], edx ; first 8 bits are the control we sent, next two are the 
    test dl, init
    jnz init_timer

    init_timer:
        xor edx, edx
        xor dl, dl
        mov dx, 0x43
        mov al, [usage]
        out dx, al
        mov bl, [usage]
        test bl, 0b0000001 
        jnz .chan0
        test bl, 0b00000010
        jnz .chan2
        jmp .error ; we cant read (0b11) or use chan 1 (0b01), so we give an error, well "read" both ways still write to the same reg, but the reload will be different

        .chan0:
            mov dx, 0x40
            mov al, [usage+1]
            out dx, al
            mov al, [usage+2]
            out dx, al
            jmp .return
        
        .chan2:
            mov dx, 0x42
            mov al, [usage+1]
            out dx, al
            mov al, [usage+2]
            out dx, al
            jmp .return

        .error:
            mov ebx, error_invalid_chan
            mov ah, 0x0f
            mov dl, print_char | loop_func
            call print
            jmp .return

        .return:
            xor dl, dl ;we just make sure dl is always reset before we exit, just incase we forget anywhere
            ret

error_invalid_chan db "The channel you gave was invalid, please try again with a valid channel",0
usage dd 0x00
init equ 0b00000001
    ;vga driver
        print_char equ 0b00000001
        loop_func  equ 0b00000010
        res_scr    equ 0b00000100
        clr_scr    equ 0b00001000
        N_line     equ 0b00010000
        start_vga  equ 0b00100000
        print      equ 0x10c800
times 512 db 0 