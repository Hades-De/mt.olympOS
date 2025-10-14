[org 0x1c8400]
[bits 32]
;exit regs
;eax:ebx, when it found usable memory
;edi as offset for the unalloc, when unallocating, this is set to together with eax:ebx, and dl =0b00000010
;cx is set with error flags
;0x01 is no more ram
;;to do, still have to make an unalloc
test dl, reset_flag
jnz reset
mov eax, ecx ;ecx is the amount of 4kb sectors we need, not yet added. will add this later, 

TESTING:
    mov dword [total_pages_used], 0x1
    mov byte [pages], 2
    mov byte [total_possible_pages], 0x02
    mov edi, 16
    mov dword [total_possible_pages + edi], 0x01
    add edi, 16
    mov dword [total_possible_pages + edi], 0x01
    mov byte [used_map + 0], 0       ; used
    mov byte [used_map + 1], 1       ; free
    mov byte [used_map + 2 + 16], 1       ; used
    mov byte [used_map + 3 + 16], 0       ; free
    mov byte [used_map + 4 + 32], 0       ; free
    mov byte [used_map + 5 + 32], 1       ; used
    mov byte [used_map + 6 + 32], 0       ; free

jmp alloc_mem

alloc_mem: ;alloc mem routine
    cmp dword [pages], 0
    jne .pass
    ret
.pass:
    call check_enough_length
    cmp ecx, 1
    jne give_out_alloc
    ret

    check_enough_length:
        xor edi, edi
        xor ecx, ecx
        mov [offset_length_finder], ecx ;make sure the offset starts at 0
        .loop:
            mov ebx, [total_possible_pages + edi]; these three lines check if logically theres even enough in this map- 1/3 
            cmp [pages], ebx ; in cases they do have it, but scattered, my other lines will help-2/3
            jg .add_16 ; but this just just the existance of said length in this part, also stops it from going into space 3/3
            ;this does a very small safety check, later i will add a better one that checks the current pages +whatever it wants, it its too much it'd reject
            pusha
            ;call check_used_pages
            popa
            mov ebx, [pages]
            add ebx, [total_pages_used]
            cmp ebx, [total_possible_pages + edi]
            jg .add_16
            mov edx, [offset_length_finder]
            cmp edx, [total_possible_pages + edi]
            jge .add_16
            mov ah, [used_map + edx + edi]; moves the current byte of the map of whats used and what isnt into ah
            cmp ah, 0 ; 0= unused
            jne .retry ; empties the map, and retries it with the next entry
            add ecx, 1 ; add one to our total free (4kb) sector count
            mov byte [used_map + edx + edi], 1 ;set it as used
            cmp ecx, [pages] ;compare it to the amount of pages we want
            jge found_loc ;if it found equal or greater than enough pages, we jump to "found_loc"
            inc dword [offset_length_finder];increases the value so that we dont read the same one again
            jmp .loop ;tries again

        .retry:
            mov esi, [offset_length_finder]; moves the value into esi
            inc dword [offset_length_finder] ;increases the dword by 1, because thats the value it should check next
            .reset_loop:
                cmp ecx, 0; compares ecx to 0 INCASE THIS IS THE FIRST ONE
                je .loop;if it is, we just jump back
                mov byte [used_map + esi + edi -1], 0; we put the value of 0 (unused) at 0x70000 +the offset + the amount of map offset -1 because we want the one right before it
                dec ecx ;decreases ecx, because its basically the "amount" we already ghostallocated, if its 0, then we know it was the last one
                dec esi ;decreases esi, because we want to go down the map
                jmp .reset_loop ;jumps back until ecx=0

        .add_16:
            .reset_loop_16:
                cmp ecx, 0; compares ecx to 0 INCASE THIS IS THE FIRST ONE
                je .continue;if it is, we just jump back
                mov byte [used_map + esi + edi -1], 0; we put the value of 0 (unused) at 0x70000 +the offset + the amount of map offset -1 because we want the one right before it
                dec ecx ;decreases ecx, because its basically the "amount" we already ghostallocated, if its 0, then we know it was the last one
                dec esi ;decreases esi, because we want to go down the map
                jmp .reset_loop_16 ;jumps back until ecx=0
            .continue:
                add edi, 16 ;adds (in this case 16, could be any value, its highly dependend on the largest page number we have)
                mov edx, [total_possible_pages + edi] ;we check if its full of zero's
                cmp edx, 0
                jne .loop ; if its not, its safe to assume its still a valid page
                mov ebx, full_pages
                mov ah, 0x0f
                mov dl, print_char | loop_func
                call print
                mov ecx, 1 ; moves the error bit into ecx
                ret

        check_used_pages:
            mov dword [total_pages_used], 0
            xor ecx, ecx
            .loop:
                cmp ecx, [total_possible_pages + edi] ;checks if we have checked the max amount of pages here
                je .return
                mov edx, [offset_length_finder]
                mov ah, [used_map + edx + edi]; moves the current byte of the map of whats used and what isnt into ah
                inc ecx
                cmp ah, 1 ; 1= used
                je .add_to_amount
                inc dword [offset_length_finder]
                jmp .loop

            
                .add_to_amount:
                    inc dword [total_pages_used]
                    inc dword [offset_length_finder]
                    jmp .loop

                .return:
                    ret


        found_loc:
            mov ecx, [offset_length_finder]
            shl ecx, 12 ; basically mult by ^12, because we want the value of ecx to be multiplied by 4096
            mov [offset_length_finder], ecx
            xor ecx, ecx
            ret ; return to alloc_mem

        give_out_alloc: ; gives out eax:ebx, and edi as an offset
            push edi
            mov ebx, gave
            mov ah, 0x0f
            mov dl, print_char | loop_func
            call print
            mov ebx, pages
            mov ah, 0x0f
            mov dl, print_char | loop_func
            call print
            pop edi
            call load_address
            add ecx, [offset_length_finder] ;adds the offset aswell
            mov [outputs], ecx ;moves the outputs to edx:ecx
            mov [outputs + 4], edx
            ret

load_address:;WHEN CALLING THESE. MAKE SURE EDI IS ALWAYS SET THE SAME BOTH CALLS!!!
    mov ecx, [map_start + edi] ; load the start of the adress into ecx, the low byte
    mov edx, [map_start + edi+ 4] ; mov the high bytes of the adress into edx
    ret

update_used_list_disable:
    shr edi, 4 ;basically div by 4
    mov byte [used_map + edi], 0 
    shl edi, 4 ; basically mult by 4
    ret

load_lengths:;WHEN CALLING THESE. MAKE SURE EDI IS ALWAYS SET THE SAME BOTH CALLS!!!
    mov ecx, [map_start + edi + 8] ; mov the low bytes of the length into ecx
    mov edx, [map_start + edi + 12] ; mov the high bytes of the length into edx
    ret

reset: ;resets the sector map with usable sectors, incase we need to look again or an error/corruption


gave db "gave out 'num' of pages, at 'num1'", 0
full_pages db "[E]pages are full, try again later", 0
total_pages_used dd 0
offset_length_finder dd 0
pages dd 0
total_possible_pages dd 0
map_start equ 0x1c9000
reset_flag equ 0b00000001
unalloc_flag equ 0b00000010
used_map equ 0x70000
sector_map_start equ 0x600
sector_map_end equ 0x7BFD ; it should be 0x7bff, but since its so close to our stack, we want that extra safety buffer
outputs equ 0x550
    ;vga driver
        print_char equ 0b00000001
        loop_func  equ 0b00000010
        res_scr    equ 0b00000100
        clr_scr    equ 0b00001000
        N_line     equ 0b00010000
        start_vga  equ 0b00100000
        print      equ 0x1c8000
times 1024 - ($ - $$) db 0