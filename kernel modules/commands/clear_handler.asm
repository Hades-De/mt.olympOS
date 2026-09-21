clear_command:
    mov eax, 0x04
    int 0x80
    jmp return_kernel