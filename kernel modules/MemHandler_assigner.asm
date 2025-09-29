[org 0x1c8400]
[bits 32]
xor edi, edi
;push ecx ;ecx is the amount of sectors we need
find_non_used_map:
    mov esi, [map_start + edi + 16] ; load current map (only the used byte)
    test esi, esi ;test if its used
    je not_used
    test eax, eax ;test if eax si empty, if it is, pretty likely its out of maps
    je no_space
    add edi, 32
    jmp find_non_used_map

not_used:
    mov ebx, free
    mov ah, 0x0f
    mov dl, print_char | loop_func
    call print
   ;pop ecx
    ret

load_regs:
    mov eax, [map_start + edi] ; load the start of the adress into eax, the low byte
    mov ebx, [map_start + edi+ 4] ; mov the high bytes of the adress into ebx
    mov ecx, [map_start + edi + 8] ; mov the low bytes of the length into ecx
    mov edx, [map_start + edi + 12] ; mov the high bytes of the length into edx
    ret

no_space:
    mov ebx, nospc
    mov ah, 0x0f
    mov dl, print_char | loop_func
    call print
    ;pop ecx
    ret

map_start equ 0x1c8600
nospc db "No RAM left, please wait with loading files!",0
free db "memory free!",0
    ;vga driver
        print_char equ 0b00000001
        loop_func  equ 0b00000010
        res_scr    equ 0b00000100
        clr_scr    equ 0b00001000
        N_line     equ 0b00010000
        start_vga  equ 0b00100000
        print      equ 0x1c8000
times 512 - ($ - $$) db 0