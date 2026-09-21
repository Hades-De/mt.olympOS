dump_command:
    mov eax, 0x06
    int 0x80
    jmp return_kernel