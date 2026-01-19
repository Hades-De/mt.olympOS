;turns said program (hex loc in 0x550)
;to do, translation algo. read up on it.
;tables tables tables
[org 0x10d200]
[bits 32]
    test dl, init ; init has the prio 1,2 and 3 in the 16 bit regs of ebx +cx cx= prio1 high ebx = prio3 low ebx= prio2
    jnz init_PID
    jmp return



    init_PID:
        mov [prio_1], cx
        mov [prio_2], bx
        shr ebx, 16 ;moves the highest bits to the lower 16 bits
        mov [prio_3], bx
        add dword [prio_1], 0x100000
        add dword [prio_2], 0x100000
        add dword [prio_3], 0x100000
        mov ebx, init_correct
        mov ah, 0x0f
        mov dl, print_char | loop_func
        call print
        mov dl, N_line
        call print
        xor dl, dl
        ret

    return:
        xor dl, dl
        ret
    






;variables
            init        equ 0b00000001
            loop_func   equ 0b00000010
            res_scr     equ 0b00000100
            clr_scr     equ 0b00001000
            N_line      equ 0b00010000
            print_char  equ 0b00100000
            print       equ 0x10c800
            time_slot_max db 100
    ;RRtable
        prio_1 dd 0x00
        prio_2 dd 0x00
        prio_3 dd 0x00

;text
    init_correct db "Pid generator init has worked"
    text_end db 0x00
            
times 1024 - ($ - $$) db 0