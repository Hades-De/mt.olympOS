org 0x7E00

    mov ah, 0x0E  
    mov al, 'T'   
    int 0x10


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
    db "",0
    
end:
    jmp $
