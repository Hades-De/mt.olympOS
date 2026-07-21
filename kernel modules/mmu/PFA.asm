[org 0x10d000]
[bits 32] 
init: ;pushes in order: alloc, bitmap, unalloc
    pop eax
    mov edi, bitmap
    mov ecx, find_free_bloc
    mov ebx, free_block
    push ebx
    push edi
    push ecx
    push eax
    ret


find_free_bloc:; malloc 1 page, returns the page in eax
    mov edi, bitmap
    xor ebx, ebx          

    .find_byte:
        mov al, [edi + ebx]
        cmp al, 0xFF
        jne .found_partial
        inc ebx
        jmp .find_byte

    .found_partial:
        xor ecx, ecx    

    .find_bit:
        bt ax, cx       
        jnc .free_bit  
        inc ecx
        cmp ecx, 8
        jl .find_bit

    .free_bit:
        bts ax, cx
        mov [edi + ebx], al
        mov eax, ebx
        shl eax, 3       
        add eax, ecx     
        shl eax, 12
        ret

free_block:; marks the page in eax as empty
    shr eax, 12
    xor edx, edx
    mov edi, bitmap
    mov ebx, eax
    mov ecx, ebx
    shr ebx, 3          ; byte index
    and ecx, 7          ; bit index
    mov dl, 1
    shl dl, cl
    not dl
    and [edi + ebx], dl
    ret


;var
    allocator db 0x00
    bitmap:
        times 4096 db 0xff

times 5120 - ($ - $$) db 0xfe