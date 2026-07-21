[org 0x10e600]
[bits 32]

init: 
    pop eax
    pop ebx
    pop ecx
    mov dword [palloc], ebx
    mov dword [dalloc], ecx
    push eax
    ;setup 8,16 and 32 byte pools
    call [palloc]
    mov dword [pool8], eax
    mov dword [pool8 +4], 8 ;poolsize , +2 is its max size
    mov dword [pool8 +8], 0 ; poolhead
    mov esi, eax
    mov edx, 8
    mov ecx, 512
    call .init_loop
    call [palloc]
    mov dword [pool16], eax
    mov dword [pool16 +4], 16 ;poolsize
    mov dword [pool16 +8], 0 ; poolhead
    mov esi, eax
    mov edx, 16
    mov ecx, 256
    call .init_loop
    call [palloc]
    mov dword [pool32], eax
    mov dword [pool32 +4], 32 ;poolsize
    mov dword [pool32 +8], 0 ; poolhead
    mov esi, eax
    mov edx, 32
    mov ecx, 128
    call .init_loop
    call [palloc]
    mov dword [pool64], eax
    mov dword [pool64 +4], 64
    mov dword [pool64 +8], 0
    mov esi, eax
    mov edx, 64
    mov ecx, 64
    call .init_loop
    ret

    .init_loop:
    lea eax, [esi + edx]      ; next chunk address
    mov [esi], eax          ; current->next = next
    add esi, edx              ; move to next chunk
    loop .init_loop
    ret

malloc:
    ;we assume eax holds the size
    add eax, 7
    and eax, 0FFFFFFF8h; round up to the nearest poolsize
    cmp eax, [pool8 +4]
    jle .pool8_alloc
    cmp eax, [pool16 +4]
    jle .pool16_alloc
    cmp eax, [pool32 +4]
    jle .pool32_alloc
    cmp eax, [pool64 +4]
    jle .pool64_alloc
    jge error_pfa_need

;allocs
    .pool8_alloc:
        mov eax, [pool8]
        mov ebx, [eax + 8]      ; ebx = head (first free chunk)
        test ebx, ebx
        jz error_big
        mov ecx, [ebx]          ; ecx = chunk->next
        mov [eax + 8], ecx      ; head = next
        mov eax, ebx            ; return chunk
        ret


    .pool16_alloc:
        mov eax, [pool16]
        mov ebx, [eax + 8]      ; ebx = head (first free chunk)
        test ebx, ebx
        jz error_big
        mov ecx, [ebx]          ; ecx = chunk->next
        mov [eax + 8], ecx      ; head = next
        mov eax, ebx            ; return chunk
        ret

    .pool32_alloc:
        mov eax, [pool32]
        mov ebx, [eax + 8]      ; ebx = head (first free chunk)
        test ebx, ebx
        jz error_big
        mov ecx, [ebx]          ; ecx = chunk->next
        mov [eax + 8], ecx      ; head = next
        mov eax, ebx            ; return chunk
        ret
            
    .pool64_alloc:
        mov eax, [pool64]
        mov ebx, [eax + 8]      ; ebx = head (first free chunk)
        test ebx, ebx
        jz error_big
        mov ecx, [ebx]          ; ecx = chunk->next
        mov [eax + 8], ecx      ; head = next
        mov eax, ebx            ; return chunk
        ret
            
    
error_big:
    mov edi, 1
    ret

error_pfa_need:
    mov edi, 2
    ret

;VARIABLES
    pool8  dd 0, 0, 0
    pool16 dd 0, 0 ,0
    pool32 dd 0, 0 ,0
    pool64 dd 0, 0 ,0
    palloc dd 0x00
    dalloc dd 0x00
    offset dd 0x00
times 1024 - ($ - $$) db 0