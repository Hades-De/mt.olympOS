[org 0x7E00]

data:
    free_mem1 dd 0
    Res_mem1 dd 1
    Res_mem2 dd 2
    free_mem2 dd 3
    Res_mem3 dd 4
;;other code
    mov ah, 0x0E  
    mov al, 'T'   
    int 0x10

lowermemcheck:
    clc
    int 0x12
    jc wrong_memory ;;carry flag is set when its not detected, but it should be
    cmp ax, 640 ;;ax contains the amount of RAM in kb, starting from 0, "640kb outta be enough for anybody"
    je pre_memoryMap


SegmentedRegClear:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax


reset_64bit:
    clc
    xor eax,eax
    mov ebx, eax
    iret

pre_memoryMap:
    push eax ;;pushes whatever its doing onto the stack
    xor eax, eax
    xor dh, dh
    mov es, ax ;;copies 0x0000 onto es
    mov di, 0x8000 ;;memory map buss
    jmp memoryMap

memoryMap:
    call reset_64bit ;;speaks for itself
    mov edx, 0x534D4150 ;;magic numbers
    mov eax, 0xE820 ;; eax = E820
    mov ecx, 24 ;;funny
    int 15h ;;bios func int 15h, EAX=0xE820s
    cmp eax, 0x534D4150 ;;if its successful this will be equal
    jne wrong_memory
    jc wrong_memory ;; "carryflag", 0 ;;if successfull continue, if not whoomp whoomp
    cmp ebx, 0 ;;ebx should be bigger than zero if its zero, we are done reading the list
    jl sort_mMap
    je GTD_start
    add di, cx
    jmp memoryMap
    ;;memory map begins at 0x00008000

sort_mMap:
    mov [free_mem1], ecx
    cmp ecx, [free_mem1]
    je memoryMap
    mov [Res_mem1], ecx
    cmp ecx, [Res_mem1]
    je memoryMap
    mov [Res_mem2], ecx
    cmp ecx, [Res_mem2]
    je memoryMap
    mov [free_mem2], ecx
    cmp ecx, [free_mem2]
    je memoryMap
    mov [Res_mem3], ecx
    cmp ecx, [Res_mem3]
    je memoryMap    
    ;;add code here to sort the memory map

ckinput:
    push eax
    cmp cl, 0x32 ;;keymap should be put here + add the function to move up and down MOVES IT DOWN 
    je print_From_Kb
    cmp cl, 0x13 ;;enter current chosen kernel
    pop eax
    iret

keyboardPs2:
    push eax        ;;so it could return whenever
    in al, 60h
    mov al, 20h
    out 20h, al
    mov cl, al
    pop eax
    iret           ;;returns to whatever it was doing 
                   ;;add some check for chars that could do mutliple things I.E choose kernel (check where theres no 00's or if its user specific)
print_From_Kb:
    push eax
    mov al, 60h
    int 0x10
    pop eax
    iret

print_text:
    mov al, [bx]
    cmp al, 0
    je end
    int 0x10
    inc bx
    jmp print_text

texts:
    wrong_memory:
        db "something went wrong",0

clc
cli
GTD_start:
    nulldes:
        dd 0
        dd 0

    codedes:
        dw 0xffff
        dw 0
        db 0
        dd 10011010
        dd 11001111
        db 0

    datades:
        dw 0xffff
        dw 0
        db 0
        dd 10010010
        dd 11001111
        db 0
    
    gtd_end:

    GTD_des:
        dw gtd_end - GTD_start - 1 ; size
        dd GTD_start

        CODE_SEG equ codedes - GTD_start
        DATA_SEG equ datades - GTD_start
    
end:
    jmp $
