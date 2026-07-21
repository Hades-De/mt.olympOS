[org 0x10e400]
[bits 32]
init:
    pop ebx
    mov eax, pde_fill
    push eax
    push ebx
    ret


pde_fill:
    mov dword [ebx +ecx*4], eax
    or dword [ebx +ecx*4], 3
    ret
times 512 - ($ - $$) db 0