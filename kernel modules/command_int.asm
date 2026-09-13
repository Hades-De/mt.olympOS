[org 0x10ee00]
[bits 32]
init:; command buffer input and output the handler
    pop ebp
    pop eax
    pop ebx
    pop edx
    pop edi
    pop esi
    mov dword [command_buffer], eax
    mov dword [esi_CB_stor], ebx
    mov dword [Dump_regs], edx
    mov dword [print], edi
    mov dword [clear_scr], esi
    mov eax, handle_enter
    push eax
    push ebp
    ret

%include "./commands/dump_handler.asm"
%include "./commands/clear_handler.asm"
        handle_enter:
            xor ebx, ebx
            xor ecx, ecx
            ;loop for commands
            .loop_find_command:
                mov edi, dump_cmd
                add edi, ebx
                mov esi, [command_buffer]
                mov ecx, 4 ; only checks the base. if i want to add args, i need to code it like that
                cld
                repe cmpsb
                ;if equal, its the command, parse further
                jne .skip ;ebx contains the offset for the command
                jmp found_cmd
                .skip:
                cmp ebx, command_timeout
                jge no_command
                add ebx, 4
                jmp .loop_find_command
                no_command:
                    mov eax, Dump_regs-NCM -1
                    mov ebx, NCM
                    push ebx
                    push eax
                    call [print]
                return_kernel:
                    mov ecx, [esi_CB_stor]
                    mov edx, [command_buffer]
                    xor esi, esi
                    .loop_clr_SB_buffer:
                        cmp dword[ecx], 0
                        je .done
                        mov dword [edx+esi], 0x00
                        dec dword [ecx]
                        inc esi
                        jmp .loop_clr_SB_buffer
                    .done:
                        mov ecx, [esi_CB_stor]
                        mov dword [ecx], 0x00
                        ret

                found_cmd:
                    mov eax, handler
                    add eax, ebx
                    jmp [eax]

NCM db "No command found!"
Dump_regs dd 0x00
clear_scr dd 0x00
print dd 0x00
esi_CB_stor dd 0x00
command_buffer dd 0x00
command_timeout equ 256
;cmds
    dump_cmd db "dump"
    clear_cmd db "clr" ,0x00

handler:
dd dump_command
dd clear_command
dd lover_command

times 512 - ($ - $$) db 0