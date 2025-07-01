[org 0x09000]
[bits 32]

start:
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp dword 0x08:Kernel_start   ; Jump to loaded sector

    gdt_start:
    dq 0x0000000000000000        ; null descriptor
    dq 0x00cf9a000000ffff        ; code segment: base=0, limit=4GB, flags=0x9A, gran=1
    dq 0x00cf92000000ffff        ; data segment: base=0, limit=4GB, flags=0x92, gran=1
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

Kernel_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x7c000
    xor di, di
    xor ax, ax
    mov esi, 0xB8000

idt_int_setup:
    mov edi, 0x00
    mov eax, Div_zero
    call make_idt_entry
    ;
    mov edi, 0x01
    mov eax, Debug
    call make_idt_entry
    ;
    mov edi, 0x02
    mov eax, Non_mask_int
    call make_idt_entry
    ;
    mov edi, 0x03
    mov eax, Break
    call make_idt_entry
    ;
    mov edi, 0x04
    mov eax, Overflow
    call make_idt_entry
    ;
    mov edi, 0x05
    mov eax, Bound_range_Exceeded
    call make_idt_entry
    ;
    mov edi, 0x06
    mov eax, Invalid_opcode
    call make_idt_entry
    ;
    mov edi, 0x07
    mov eax, Device_not_available
    call make_idt_entry
    ;
    mov edi, 0x08
    mov eax, Double_fault
    call make_idt_entry
    ;
    mov edi, 0x09
    mov eax, Coproc_overrrun
    call make_idt_entry
    ;
    mov edi, 0x0A
    mov eax, Invalid_TTS
    call make_idt_entry
    ;
    mov edi, 0x0B
    mov eax, Seg_not_pres
    call make_idt_entry
    ;
    mov edi, 0x0C
    mov eax, Stack_seg_fault
    call make_idt_entry
    ;
    mov edi, 0x0D
    mov eax, Gen_prot_fault
    call make_idt_entry
    ;
    mov edi, 0x0E
    mov eax, Page_fault
    call make_idt_entry
    PIC_unmask:
        ; Send ICW1 (initialize PICs)
        mov al, 0x11
        out 0x20, al       ; master PIC
        out 0xA0, al       ; slave PIC

        ; Send ICW2 (vector offset)
        mov al, 0x20       ; remap master to 0x20-0x27
        out 0x21, al
        mov al, 0x28       ; remap slave to 0x28-0x2F
        out 0xA1, al

        ; Send ICW3 (wiring info)
        mov al, 0x04       ; slave on IRQ2
        out 0x21, al
        mov al, 0x02       ; cascade identity
        out 0xA1, al

        ; Send ICW4 (environment info)
        mov al, 0x01
        out 0x21, al
        out 0xA1, al

        mov edi, 0x20
        mov eax, timer
        call make_idt_entry

        mov edi, 0x21
        mov eax, keyboard
        call make_idt_entry

        mov edi, 0x2E
        mov eax, Disk_ATA_Handler
        call make_idt_entry

        ; Mask everything except IRQ0 (timer), for now
        mov al, 0b11111100
        out 0x21, al
        mov al, 0xFF
        out 0xA1, al


lidt [idt_ptr]
sti

hechloopd:
    cmp byte [enter_en], 1
    je parsing_setup
    hlt
    jmp hechloopd

parsing_setup: ;0x530 isthe start adress
    mov esi, [buffer_ptr]
    mov ebx, [vid_counter]
    call next_line
    parsing:
        xor ebx, ebx
        mov [vid_counter], ebx
        mov [buffer_ptr], esi
        mov edi, 0x530 
        mov al, [edi +2]
        test al, al
        je two_byte_command

    four_byte_command:
        cmp dword [edi], 'echo'
        je echo
        cmp dword [edi], 'ping'
        je ping
        jmp command_not_found

    two_byte_command:
        cmp dword [edi], 'ls'
        je ls
        jmp command_not_found\

return:
    ret

    functions:
        next_line:
            cmp ebx, 79
            jge return
            mov ah, 0x0f
            mov al, ' '
            mov word [esi], ax
            add esi, 2
            inc ebx
            jmp next_line

        four_letter:
            echo:
                mov ah, 0x0f
                add edi, 4
                mov ebx, edi
                mov ah, 0x0f
                call print
                jmp command_done
                ;jmp to end

            ping:
                jmp command_done
        
        two_letter:
            ls:
            jmp command_done

    command_not_found:
        mov ebx, noCom
        mov ah, 0x0f
        call print
    command_done:
        call next_line
        mov [buffer_ptr], esi
        mov edi, 0x7000
        call clear_buffer
        mov edi, 0x530
        mov [CMD_string], edi
        mov byte [enter_en], 0
        jmp hechloopd
    clear_buffer:
        mov byte [edi], 0x00
        dec edi
        cmp edi, 0x530
        ja clear_buffer
        ret

        

exec_idt:
    Div_zero:
        pusha
        mov ah, 0x04
        mov ebx, zero
        call print
        popa
        cli
        hlt
        jmp $

    Debug:
        pusha
        mov ah, 0x04
        mov ebx, debug
        call print
        popa
        cli
        hlt
        jmp $

    Non_mask_int:
        pusha
        mov ah, 0x04
        mov ebx, nmi
        call print
        popa
        cli
        hlt
        jmp $
        
    Break:
        pusha
        mov ah, 0x04
        mov ebx, breakp
        call print
        popa
        cli
        hlt
        jmp $
        
    Overflow:
        pusha
        mov ah, 0x04
        mov ebx, zero
        call overf
        popa
        cli
        hlt
        jmp $
        
    Bound_range_Exceeded:
        pusha
        mov ah, 0x04
        mov ebx, bre
        call print
        popa
        cli
        hlt
        jmp $
        
    Invalid_opcode:
        pusha
        mov ah, 0x04
        mov ebx, inop
        call print
        popa
        cli
        hlt
        jmp $
        
    Device_not_available:
        pusha
        mov ah, 0x04
        mov ebx, dna
        call print
        popa
        cli
        hlt
        jmp $
        
    Double_fault:
        pusha
        mov ah, 0x04
        mov ebx, df
        call print
        popa
        cli
        hlt
        jmp $
        
    Coproc_overrrun:
        pusha
        mov ah, 0x04
        mov ebx, cso
        call print
        popa
        cli
        hlt
        jmp $
        
    Invalid_TTS:
        pusha
        mov ah, 0x04
        mov ebx, intts
        call print
        popa
        cli
        hlt
        jmp $
        
    Seg_not_pres:
        pusha
        mov ah, 0x04
        mov ebx, snp
        call print
        popa
        cli
        hlt
        jmp $
        
    Stack_seg_fault:
        pusha
        mov ah, 0x04
        mov ebx, ssf
        call print
        popa
        cli
        hlt
        jmp $
        
    Gen_prot_fault:
        pusha
        mov ah, 0x04
        mov ebx, gpf
        call print
        popa
        cli
        hlt
        jmp $
        
    Page_fault:
        pusha
        mov ah, 0x04
        mov ebx, pf
        call print
        popa
        cli
        hlt
        jmp $

    timer:
        pusha
        mov esi, [buffer_ptr]        ; video memory ptr (cursor location)     
        mov al, [cursor_timer]
        dec al
        mov [cursor_timer], al
        cmp al, 0
        jne .skip_toggle             ; if timer not zero, skip toggle
        ; Timer hit zero, toggle cursor visibility
        mov al, [cursor_vis]
        xor al, 1                   ; flip 1 -> 0 or 0 -> 1
        mov [cursor_vis], al
        ; Reset countdown timer to 10 (arbitrary blink speed)
        mov byte [cursor_timer], 10
        .skip_toggle:
            ; Write cursor character or clear it depending on cursor_vis
            mov al, [cursor_vis]
            cmp al, 1
            jne .hide_cursor

            ; Cursor ON: print underscore 0x5F with attribute 0x0F
            mov ax, 0x0F5F              ; 0x0F attribute + 0x5F underscore
            mov word [esi], ax
            jmp .done

        .hide_cursor:
            ; Cursor OFF: clear the character (space with attribute 0x07)
            mov ax, 0x0720              ; normal gray space
            mov word [esi], ax

        .done:
            ; Send EOI to PIC and exit
            mov al, 0x20
            out 0x20, al
            popa
            iret

    keyboard:
        pusha
        in al, 0x60             ; Read scancode
        cmp al, 0x80
        jae key_release        ; Ignore key releases

        ; Translate scancode to ASCII
        movzx bx, al
        mov edx, scancode_table
        add edx, ebx
        mov al, [edx]
        mov edi, [CMD_string]
        mov esi, [buffer_ptr]
        mov ecx, [vid_counter]


        ;check if its the enter key
        cmp al, 2
        je set_enter
        cmp al, 1
        je backspace
        jmp print_keyboard
        
        set_enter:
            mov byte [enter_en], 1
            jmp key_release


        ; Print character at video memory pointed by ESI and puts it in a string holder
        print_keyboard:
            inc ecx
            mov [vid_counter], ecx
            mov byte [edi], al
            inc edi
            mov [CMD_string], edi
            mov ah, 0x0F
            mov word [esi], ax
            add esi, 2
            mov [buffer_ptr], esi
            cmp esi, 0xB8F9E        ; Screen end? Reset cursor
            jae reset_cursor

        key_release:
            mov al, 0x20
            out 0x20, al            ; EOI PIC
            popa
            iret

        reset_cursor:
            mov esi, 0xB8000
            mov [buffer_ptr], esi
            jmp key_release        ; EOI and return

    Disk_ATA_Handler:
        pusha
        mov dx, 0x1F7
        in al, dx
        mov byte [Disk_ATA], 1
        mov al, 0x20
        out 0x20, al
        popa
        iret

read_Disk_Ata:     ; Enable IRQ14 (ATA primary) on slave PIC
    in al, 0xA1
    and al, 0b10111111
    out 0xA1, al

    in al, 0x21
    and al, 0b11111011
    out 0x21, al

    mov dx, 0x1F2
    mov al, 100
    out dx, al

    mov dx, 0x1F3
    mov al, 0x0E
    out dx, al

    mov dx, 0x1F4
    xor al, al
    out dx, al

    mov dx, 0x1F5
    xor al, al
    out dx, al

    mov dx, 0x1F6
    mov al, 0xE0
    out dx, al

    ; READ SECTORS command
    mov dx, 0x1F7
    mov al, 0x20
    out dx, al

    ; Set up loop
    mov edi, 0x100000      ; 1 MiB destination
    mov ecx, 100           ; 100 sectors

    .read_loop:
        .wait_irq:
            cmp byte [Disk_ATA], 1
            jne .wait_irq
            mov byte [Disk_ATA], 0

            mov dx, 0x1F0
            mov cx, 256
            rep insw

            add edi, 512
            loop .read_loop

            ; Disable IRQs again
            mov al, 0b11111100
            out 0x21, al
            mov al, 0xFF
            out 0xA1, al
            ret

backspace:
    cmp esi, 0xb8000
    jbe key_release
    cmp edi, 0x530
    jbe esi_sub
    mov byte [edi], ' '
    sub edi, 1
    esi_sub:
        mov word [esi], ' '
        sub esi, 2
        mov word [esi], ' '
        mov [buffer_ptr], esi
        mov [CMD_string], edi
        jmp key_release

print: ;EXPECTS EBX TO HAVE STRING, AND COLOR BYTE TO BE SET!!! in ah
    mov esi, [buffer_ptr]
    mov edi, [vid_counter]
    print_loop:
        mov al, [ebx]
        test al, al
        je done
        mov word [esi], ax
        add esi, 2
        inc ebx
        inc edi
        cmp esi, 0xB8F9E        ; Screen end? Reset cursor
        jae reset_cursr
        jmp print_loop



    reset_cursr:
        mov esi, 0xB8000
        mov [buffer_ptr], esi
        inc edi
        jmp print_loop

    done:
        mov [vid_counter], edi
        mov [buffer_ptr], esi
        ret
; eax = handler address
; edi = index
make_idt_entry:
    ; Set low 16 bits of handler
    mov word [idt + edi*8 + 0], ax              
    ; Set segment selector (e.g. 0x08 for kernel code)
    mov word [idt + edi*8 + 2], 0x08            
    ; Set zero byte
    mov byte [idt + edi*8 + 4], 0               
    ; Set type + flags: 0x8E = present + ring 0 + 32-bit interrupt gate
    mov byte [idt + edi*8 + 5], 0x8E            
    ; Set high 16 bits of handler
    shr eax, 16
    mov word [idt + edi*8 + 6], ax              
    ret

idt:
    times 256 dq 0
idt_ptr:
    dw 256 * 8 - 1
    dd idt

zero db '[E]0x00 Div by 0 error!',0
debug db '[D]0x01 Debug int!',0
nmi db '[E]0x02 Non-maskable int error!',0
breakp db '[D]0x03 Breakpoint int',0
overf db '[E]0x04 Integer overflow',0
bre db '[E]0x05 Bound range exceeded',0
inop db '[E]0x06 Invalid Opcode',0
dna db '[D]0x07 Device not available',0
df db '[E]0x08 Double fault',0
cso db '[E]0x09 Coprocessor seg overrun',0
intts db '[E]0x0A invalid TTS',0
snp db '[E]0x0B segment not present',0
ssf db '[E]0x0C stack-segment fault',0
gpf db '[E]0x0D general protection fault',0
pf db '[E]0x0E Page fault, mem acc fail',0
noCom db 'No command found!',0
buffer_ptr dd 0xB8000
CMD_string dd 0x530
vid_counter dd -1
cursor_timer db 10               ; countdown timer (ticks before toggle)
cursor_vis   db 1                ; cursor visible flag (1=visible, 0=invisible)
enter_en dd 0 ; 1= enter was pressed
Disk_ATA: dq 0
scancode_table:
    db '#','$','1','2','3','4','5','6','7','8','9','0','-','=',1,'@'
    db 'q','w','e','r','t','y','u','i','o','p',"[","]",2,'^','a','s','d','f'
    db 'g','h','j','k','l',';',0,0,0,'/','z','x','c','v','b','n','m',',','.','\',0,0,0,'0x20'
    times (128-48) db 0
times 5120 - ($ - $$) db 0