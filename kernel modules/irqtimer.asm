[org 0x10cc00]
[bits 32]
;gives a blinking time for the cursor
;gives a timer for the priobased Round Robin scheduler
;1193182/desired hz = >to hex
    init:
        mov [usage], ebx ; first 8 bits are the control we sent, next two bytes are the divisor/reload value
        mov dword [vga_tty], eax
        jmp init_timer

    init_timer:
        xor ebx, ebx
        xor dl, dl
        mov dx, 0x43
        mov al, [usage]
        out dx, al
        mov bl, [usage]
        test bl, 0b00000001 
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
            mov ebx, set_timer
            mov eax, text_end - set_timer -1
            call [vga_tty]
            ret
        
        .chan2:
            mov dx, 0x42
            mov al, [usage+1]
            out dx, al
            mov al, [usage+2]
            out dx, al
            mov ebx, set_timer
            mov eax, text_end - set_timer -1
            call [vga_tty]
            ret

        .error:
            mov ebx, error_invalid_chan
            mov eax, set_timer - error_invalid_chan -1
            call [vga_tty]
            ret

error_invalid_chan db "The channel you gave was invalid, please try again with a valid channel"
set_timer db "The timer has been set!"
text_end db 0x00
usage dd 0x00
vga_tty dd 0x00
times 512 - ($ - $$) db 0