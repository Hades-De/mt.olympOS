[org 0x1c8400]
[bits 32]
test dl, reset_flag
jnz reset
xor edi, edi
;push ecx ;ecx is the amount of sectors we need
push ecx

sort:
    call .load_lengths
    call .test_zero
    shrd ecx, edx, 12 ;shift high dword by 12
    shr edx, 12 ;now ecx:edx is the amount of 4kb pages we have at this location.
    call .load_address  
    call .save
    add edi, 16
    jmp sort

.save:
    mov [sector_map_start + edi], eax ; save the start of the adress to the value of usable ram plus the offset
    mov [sector_map_start + edi + 4], ebx ;save the high adress into that plus 4 bytes
    mov [sector_map_start + edi + 8], ecx ;save the low bytes of the length into the location +8
    mov [sector_map_start + edi + 12], edx ;save the high bytes of the length at last ; we can inc by 16, because this *is* the list for usable ram, so we dont need a flag for itd
    ret
.test_zero:
    or edx, ecx
    jz return
    ret

.load_address:;WHEN CALLING THESE. MAKE SURE EDI IS ALWAYS SET THE SAME BOTH CALLS!!!
    mov eax, [map_start + edi] ; load the start of the adress into eax, the low byte
    mov ebx, [map_start + edi+ 4] ; mov the high bytes of the adress into ebx
    ret
.load_lengths:;WHEN CALLING THESE. MAKE SURE EDI IS ALWAYS SET THE SAME BOTH CALLS!!!
    mov ecx, [map_start + edi + 8] ; mov the low bytes of the length into ecx
    mov edx, [map_start + edi + 12] ; mov the high bytes of the length into edx
    ret

reset: ;resets the sector map with usable sectors, incase we need to look again or an error/corruption
    xor ebx, ebx 
    mov ecx, sector_map_start
    .loop:
        mov [ecx], ebx
        cmp ecx, sector_map_end ;check if its at/over the end (this is why i have a bufferzone)
        jge return
        add ecx, 4 ; add four bytes because ebx is that big
        jmp .loop
    return:
        xor edi, edi
        call sort
        ret

map_start equ 0x1c8600
nospc db "No RAM left, please wait with loading files!",0
free db "memory free!",0
reset_flag equ 0b00000001
sector_map_start equ 0x600
sector_map_end equ 0x7BFD ; it should be 0x7bff, but since its so close to our stack, we want that extra safety buffer
    ;vga driver
        print_char equ 0b00000001
        loop_func  equ 0b00000010
        res_scr    equ 0b00000100
        clr_scr    equ 0b00001000
        N_line     equ 0b00010000
        start_vga  equ 0b00100000
        print      equ 0x1c8000
times 512 - ($ - $$) db 0