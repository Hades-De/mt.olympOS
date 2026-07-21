[bits 32]
[org 0x10ce00]
pop ebx
mov eax, 0xfff7fc00
neg eax
mov dword [0x500], eax
pop eax
mov dword [bitmap], eax
push ebx
xor edi, edi
load_map:
    mov esi, [map_start + edi + 16] ; edi is the offset
    test esi, esi
    je ignore ; we test if its all 0's, if it is we can say that its either invalid, test the next one, if its still 0. then we're done
    cmp esi, 1; if its not zero, its either reserved. or unusable. if we want to save reserverd, i'll make a list for it later
    jg .reserverd; change if i want to do something with reserved cased
    jmp .save_usable

.load_regs:
    mov eax, [map_start + edi] ; load the start of the adress into eax, the low byte
    mov ebx, [map_start + edi+ 4] ; mov the high bytes of the adress into ebx
    mov ecx, [map_start + edi + 8] ; mov the low bytes of the length into ecx
    mov edx, [map_start + edi + 12] ; mov the high bytes of the length into edx
    ret

.save_usable: ;usable map overrides the VGA memory, prolly in the .loop
    call .load_regs
    push edi
    mov edi, [storage_save]
    mov [usable_ram + edi], eax ; save the start of the adress to the value of usable ram plus the offset
    mov [usable_ram + edi + 4], ebx ;save the high adress into that plus 4 bytes
    mov [usable_ram + edi + 8], ecx ;save the low bytes of the length into the location +8
    mov [usable_ram + edi + 12], edx ;save the high bytes of the length at last ; we can inc by 16, because this *is* the list for usable ram, so we dont need a flag for itd
    push edi
    .test_space: ; it should check if the current area is possibly outside out memory map
        clc
        adc dword [0x500], ecx
        jnc .skip_carry
        add dword [0x504], 1
        clc
        .skip_carry:
            mov esi, ecx
            add esi, eax
            shr esi, 12
            shr eax, 12
            cmp eax, 4096
            jge .skip
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    mov edi, [bitmap]
    .loop:
        mov ebx, eax
        mov ecx, ebx
        shr ebx, 3          ; byte index
        and ecx, 7          ; bit index
        mov dl, 1
        shl dl, cl
        not dl
        and [edi + ebx], dl
        inc eax
        cmp eax, 4096
        jg .skip
        cmp eax, esi ;add safetyrails
        jle .loop
    .skip:
    pop edi
    add edi, 16
    mov [storage_save], edi
    pop edi
    add edi, 32
    jmp load_map

.reserverd:
    call .load_regs
    cmp esi, 4
    jge ignore
    cmp esi, 2
    jne ignore
    push edi 
    mov edi, [reserved_save]
    mov [reserved_ram + edi], eax ; move eax into 0x5000 + offeset + the byte 
    mov [reserved_ram + edi + 4], ebx
    mov [reserved_ram + edi + 8], ecx
    mov [reserved_ram + edi + 12], edx
    add edi, 16
    mov [reserved_save], edi
    pop edi
    add edi, 32
    jmp load_map

ignore:
    add edi, 32
    cmp byte [empty_flag], 10
    jge .done
    add byte [empty_flag], 1
    jmp load_map

.done:
    ret

bitmap dd 0x00
hex_bin dd 0x00
empty_flag db 0
storage_save dd 0
reserved_save dd 0 
map_start equ 0x8000
reserved_ram equ 0x5000
usable_ram equ 0x600
times 512 - ($ - $$) db 0