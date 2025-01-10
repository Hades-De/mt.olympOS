[org  0x7C00]
clc
SegmentedReg:
    mov [0x7e10], dl
    xor ax, ax 
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x0500

    ;;things to still add:
    ;detection if the system is already installed
    ;a way to IO with Potential video cards/ other pcie cards
    ;possibly internet connection? but first kernel and GUI

stack_setup: ;; planning to use  0x7F00 to 0x7FFF thus 255 spaces and we'll store space left at 0x7EFE
    ;;we will assume everything pushed onto the stack is 16bits
    ;;cx is the volume counter
    ;;ax is used as a pushing variable
    mov sp, 0x7FFF
    mov word [0x7EFE], 256

lowermemcheck:
    clc
    xor ax, ax
    int 0x12
    cmp ax, 639;; ax contains the amount of RAM in kb, starting from 0, "640kb outta be enough for anybody"
    jb mem_error
    call convert_to_base10

stacetc:
    mov cx, 30412          ; CX = 30,412 bytes AKA 29.75 KiB, possibly make this less to make room for second stage
;;maybe make another 2nd part for 16 bit kernel operations if the user has less than 640kb of RAM
highmemchk:
    prechk:
        xor dx, dx
        xor ax, ax
        xor di, di
        mov es, ax
        mov di, 0x0500
        cmp di, 0x0500
        jne prechk
    ;;es:di = 0x00000500
    int15820:
        clc
        xor ebx, ebx
        xor eax, eax
        mov edx, 0x534D4150
        mov eax, 0xE820
        mov ecx, 24
        int 0x15
    pastcheck:
        jc done
        cmp eax, 0x534D4150
        jne mem_error_eax
        cmp ebx, 0 
        je done
        clc
        movzx dx, cl        ; Zero-extend CL into DX (DX = 0000:CL)
        sub cx, dx          ; Subtract DX from CX
        jc buffer_full      ; Jump if there's a carry, meaning the buffer is too small
        clc
            CLchk:
                cmp cl, 0x20 ;32 byte
                je validmem
                cmp cl, 0x14 ;20 byte
                je validmem
                cmp cl, 0x18 ;24 byte
                je validmem
                jmp validmem

            validmem:
                add di, dx
                mov edx, 0x534D4150
                mov eax, 0xE820
                mov ecx, 24
                int 0x15
                jmp pastcheck

            buffer_full:
                xor ebx, ebx
                mov ah, 0x0E
                mov bx, MBF
                jmp print_string_SRT
            
            done: ;;it seems that i cant "mov al, [bx]"
                clc
                mov ax, cx
                call convert_to_base10
                xor dx, dx ;;we can now clear dx because it has no relevant data right now
                mov dx, 1
                mov ah, 0x0E
                mov bx, HMD ;;moves the string into bx
                jmp print_string_SRT

print_string_SRT:
    mov al, [bx]
    cmp al, 0
    je end
    mov ah, 0x0E
    int 0x10
    inc bx
    jmp print_string_SRT

mem_error_eax: 
    mov ah, 0x0E
    mov bx, MEE
    jmp print_string_SRT

end:
    cmp dx, 1
    je sort_mem_list
    jmp $

convert_to_base10:
    binary_to_base10:
    xor cx, cx          ; Clear CX (used to count the number of digits)
    mov bx, 10          ; Divisor for base 10

    convert_loop:
    xor dx, dx          ; Clear DX for division
    div bx              ; Divide AX by 10, quotient in AX, remainder in DX
    call add_to_stack
    push dx             ; Push remainder onto stack (this is one digit)
    inc cx              ; Increment digit counter
    test ax, ax         ; Check if AX is zero
    jnz convert_loop    ; If not zero, continue dividing

    print_digits:
    call remove_from_stack
    pop dx              ; Get the last digit from the stack
    add dl, '0'         ; Convert it to ASCII
    mov ah, 0x0E        ; BIOS teletype function
    mov al, dl          ; Move digit to AL for printing
    int 0x10            ; Print the character
    loop print_digits   ; Repeat until all digits are printed
    mov ax, [0x7BB0]
    mov ah, 0x0E  
    mov al, ' '  
    int 0x10
    iret

sort_mem_list:
    jmp $
        
    ;; you rotate 1 bit into the first 16 bits, then subtract, if carry flag is set, fail. if not, yippie, then check if it has been 16 times
    ;;the main idea behind converting binary to base 10 is to divide by 10, video about it will be linked soon:tm:. It should be a ben eater video
    ;;first display the number in CX (current amount of space in the stack)
    ;;then sort the memory list that we got from using int 0x15
    ;;pass that info to possibly the kernel and/or the second stage
    ;;also some code to parse binary/hex into decimal (possibly using an ascii table)

DiskLoad16b:
    ;something to boot the 16bit Kernel and shoud make it so that it jumps to mem error if less than 100kb of ram cuz i aint messing with that (yet :troll:)

;;DiskLoadN16b: ;; fix it aint loading shit, main problem, 0x7E00 is empty, my second stage should be there, but isn't?
  ;;  cld
    ;;mov si, 0        ; Sector index
jmp $
add_to_stack:
    sub word [0x7EFE], 2
    jc stack_full
    ret

remove_from_stack:
    add word [0x7EFE], 2
    cmp word [0x7EFE], 256
    jg stack_empty
    ret
   
mem_error:
    mov ah, 0x0E
    mov bx, MEL
    jmp print_string_SRT

disk_error:
    mov ah, 0x0E
    mov bx, DEE
    jmp print_string_SRT

stack_empty:
    mov ah, 0x0E
    mov bx, SE
    jmp print_string_SRT

stack_full:
    mov ah, 0x0E
    mov bx, SF
    jmp print_string_SRT

text:
    SE db "stack is empty!", 0
    SF db "stack is full!", 0
    DEE db " invalid disk inserted", 0
    MEL db " lower memory error", 0
    MEE db " upper memory check failed EAX", 0
    MBF db " memory buffer is full", 0
    HMD db " higher memory reading done ", 0

times 510-($-$$) db 0
db 0x55, 0xaa
