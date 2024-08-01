section .data
    phinFile db "./kernel.P", 0 ;;./kernel.P could be anything from the phin language


section .bss
    buffer: resb 1024

section .text
    global _start

    _start:
        mov ebx, phinFile
        push ebx
        cmp ebx, 0
        jg _start
        je assemble

    assemble:
        