[org 0x1c8400]
[bits 32]
;exit regs
;eax:ebx, when it found usable memory
;edi as offset for the unalloc, when unallocating, this is set to together with eax:ebx, and dl =0b00000010
;cx is set with error flags
;0x01 is no more ram
test dl, reset_flag
jnz reset
xor edi, edi
mov eax, ecx ;ecx is the amount of 4kb sectors we need, not yet added. will add this later, 
mov [pages], eax


;;to do, still have to make an unalloc


alloc_mem: ;alloc mem routine
    call check_enough_lenght
    jmp give_out_alloc

    check_enough_lenght:
        xor ecx, ecx
        mov [offset_length_finder], ecx
        .loop:
            mov eax, [total_possible_pages + ebx]
            cmp [offset_length_finder], eax
            jge .add_16
            mov esi, [used_map + offset_length_finder]; moves the current byte of the map of whats used and what isnt into esi
            cmp esi, 0 ; 0= unused
            jne .retry ; empties the map, and retries it with the next entry
            add ecx, 1 ; add one to our total free (4kb) sector count
            mov byte [used_map + offset_length_finder], 1 ;set it as used
            cmp ecx, [pages] ;compare it to the amount of pages we want
            jge found_loc ;if it found equal or greater than enough pages, we jump to "found_loc"
            inc dword [offset_length_finder];increases the value so that we dont read the same one again
            jmp .loop ;tries again

        .retry:
            inc dword [offset_length_finder];increases the value so that we dont read the same one again
            mov edi, [offset_length_finder]; moves the value into edi
            .reset_loop:
                cmp ecx, 0; compares ecx to 0 INCASE THIS IS THE FIRSTONE
                je .loop;if it is, we just jump back
                mov byte [used_map + edi], 0 ;if it isnt we want to show these are free to take, because this cant use them
                dec ecx ;decreases because we cant use them
                jmp .reset_loop ;jumps back until ecx=0
            jmp .loop

        .add_16:
            add dword [offset_length_finder], 16
            add ebx, 16
            jmp .loop

        found_loc:
            mov edi, [offset_length_finder] ;moves the base location to edi
            shl edi, 4 ; basically mult by 4
            ret ; return to alloc_mem

        give_out_alloc: ; gives out eax:ebx, and edi as an offset
            call load_address
            ret


update_used_list_disable:
    shr edi, 4 ;basically div by 4
    mov byte [used_map + edi], 0 
    shl edi, 4 ; basically mult by 4
    ret


list: ;from here on, this is the reset function
    call load_lengths
    call .test_zero
    shrd ecx, edx, 12 ;shift high dword by 12
    shr edx, 12 ;now ecx:edx is the amount of 4kb pages we have at this location.
    mov [total_possible_pages], ecx
    mov [total_possible_pages + 4], edx
    call load_address  
    call .save
    add edi, 16
    jmp list

.save:
    mov [sector_map_start + edi], eax ; save the start of the adress to the value of usable ram plus the offset
    mov [sector_map_start + edi + 4], ebx ;save the high adress into that plus 4 bytes
    mov [sector_map_start + edi + 8], ecx ;save the low bytes of the length into the location +8
    mov [sector_map_start + edi + 12], edx ;save the high bytes of the length at last ; we can inc by 16, because this *is* the list for usable ram, so we dont need a flag for itd
    ret

.test_zero:
    or edx, ecx
    test edx, edx
    jz return
    ret

load_address:;WHEN CALLING THESE. MAKE SURE EDI IS ALWAYS SET THE SAME BOTH CALLS!!!
    mov eax, [map_start + edi] ; load the start of the adress into eax, the low byte
    mov ebx, [map_start + edi+ 4] ; mov the high bytes of the adress into ebx
    ret
load_lengths:;WHEN CALLING THESE. MAKE SURE EDI IS ALWAYS SET THE SAME BOTH CALLS!!!
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
        call list
        ret

offset_length_finder dd 0
pages dd 0
total_possible_pages dd 0
map_start equ 0x1c8600
reset_flag equ 0b00000001
unalloc_flag equ 0b00000010
used_map equ 0x70000
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