[org 0x10ec00]
[bits 32]

init:
    pop ebp
    mov dword [buffer], 0x200000
    mov eax, read_keyboard
    mov ebx, offset
    mov ecx, keyboard
    push ecx
    push ebx
    push eax
    push ebp

    read_keyboard:
        mov dx, 0x60
        xor eax, eax
        in ax, dx
        test ax, 0x80
        jnz .skip ; cause its release
        mov ecx, [offset]
        mov esi, [buffer]
        mov word [esi +ecx], ax
        inc ecx
        mov dword [offset], ecx
        .skip: 
            ret


buffer dd 0x00
offset dd 0x00
%include "scancode_set1.asm"
times 512 - ($ - $$) db 0