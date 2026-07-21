[org 0x10c400]
[bits 32]
init_system_memory: ;0=check_mem 1= page_check
    call paging
    pop eax
    mov dword [add_table], eax
    call PFA
    pop ecx
    pop eax
    pop ebx
    mov dword [PFalloc], ecx
    mov dword [PFbitmap], eax
    mov dword [PFunalloc], ebx
    push eax
    call MMC
    mov ecx, 271
    .alloc_1mb:
        push ecx
        call [PFalloc]
        pop ecx
        loop .alloc_1mb

    .init_paging:
        ;init_cr3
            call [PFalloc]
            mov dword [cr3_val], eax
        ;init pd
            call [PFalloc]
            mov dword [cr3_pde], eax
            xor ecx, ecx
            mov ebx, [cr3_val]
            call [add_table]
            mov ebx, [cr3_pde]
            xor ecx, ecx
            xor eax, eax
            .loop_pte:
                call [add_table]
                add eax, 4096
                inc ecx
                cmp ecx, 1024
                jne .loop_pte
            mov eax, [cr3_val]
            mov cr3, eax
            mov eax, cr0
            or eax, 0x80000000
            mov cr0, eax  
            pop edx
            mov eax, Page_check
            mov ebx, Check_memory
            mov ecx, Valloc
            push eax
            push ebx
            push ecx
            push edx   
            ret

debug_memory:
    Page_check:
        pop edx
        ;stepthru paging, expects eax to hold the Vmem addr
        mov ebx, eax
        shr ebx, 22 ; PDE
        mov ecx, eax
        shr ecx, 12
        and ecx, 0x3ff ; PTE
        and eax, 0xFFF; offset
        push eax
        push ecx
        push ebx
        push edx
        ret
        ;stack looks like 0PDE, 1PTE, 2Offset, to the kernel
    Check_memory:
        ;expects eax to hold the mem location to check. and shows 32 4 bytes chunks of the loc
        pop edx
        mov ebx, eax
        mov ecx, 32
        loop_printmem:
            mov eax, [ebx +ecx*4]
            push eax
            dec ecx
            cmp ecx, 0
            jne loop_printmem
        push edx
        ret

Valloc:
    ;expects the Vmem loc in ebx, and  amount of kbs in eax
    .calculate_pages:
        shl eax, 10
        add eax, 4095
        shr eax, 12
        mov edx, eax  
    ;eax now holds the amount of pages

    .check_loc_vmem:
        mov eax, ebx
        call Page_check
        pop ebx
        mov dword [cr3_pde], ebx
        pop ebx
        mov dword [cr3_pte], ebx
        pop ebx ;to make sure we have a clean stack
        mov ebx, [cr3_pde]
        mov esi, [cr3_val]
        mov eax, [esi +ebx*4] ; eax now holds the pte 
        test eax, 1
        jz new_pde
        and eax, 0xFFFFF000
        mov ebx, [cr3_pte]
        mov ecx, [eax +ebx*4] ;ecx now holds the physical page
        and ecx, 0xff
        and ecx, 3
        cmp ecx, 3
        je give_clear
    .fill_pte: ;eax has the pde
        mov ebx, eax ; put the pde into ebx to ready it for the write
        mov ecx, [cr3_pte]
        push ebx
        push ecx
        call [PFalloc]
        pop ecx
        pop ebx
        call [add_table]
        jmp give_clear
    new_pde:
        call [PFalloc]
        mov ebx, [cr3_val]
        mov ecx, [cr3_pde]
        call [add_table]
        mov ebx, eax
        push ebx
        call [PFalloc]
        mov ecx, [cr3_pte]
        pop ebx
        call [add_table]
        mov edi, 2
        jmp give_clear

    give_clear:
        mov eax, cr3
        mov cr3, eax
        ret
    
;paging
    add_table dd 0x00
    cr3_pte dd 0x00
    cr3_pde dd 0x00
    cr3_val dd 0x00

;pageframe
    PFalloc dd 0x00
    PFbitmap dd 0x00
    PFunalloc dd 0x00

;adresses
    PFA equ 0x10d000
    MMC equ 0x10ce00 ;memory map creator
    Heap equ 0x10e600
    paging equ 0x10e400

;universal var
    var1 dd 0x00
times 1024 - ($ - $$) db 0