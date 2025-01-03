[BITS 16]
[ORG 0x7E00]

KERNEL_OFFSET_HIGH  equ 0xFFFFFFFF80000000
KERNEL_LOAD_SEGMENT equ 0x1000
KERNEL_LOAD_OFFSET  equ 0x0000
KERNEL_OFFSET_LOW   equ (KERNEL_LOAD_SEGMENT << 4) + KERNEL_LOAD_OFFSET
VGA_MEMORY         equ 0xB8000

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000

    mov si, stage2Message
    call print_16bit

    call enable_A20
    call load_kernel
    call enable_protected_mode

load_kernel:
    mov ah, 0x02
    mov al, 64
    mov ch, 0
    mov cl, 5
    mov dh, 0
    push KERNEL_LOAD_SEGMENT
    pop es
    mov bx, KERNEL_LOAD_OFFSET

    int 0x13
    jc disk_error
    ret

enable_A20:
    push ax
    in al, 0x92
    or al, 2
    out 0x92, al
    pop ax
    ret

enable_protected_mode:
    xchg bx, bx
    cli                             ; disable interrupt
    lgdt [gdt_descriptor]           ; load GDT descriptor

    ; init protected mode
    mov eax, cr0
    or eax, 1                       ; set PE bit
    mov cr0, eax

    jmp 0x08:protected_mode_entry   ; jump to segment 0x08

[BITS 32]
protected_mode_entry:
    ; setup segments
    mov ax, 0x10                    ; segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x200000

    mov esi, protectedModeMessage
    call print_protected_mode

    call setup_paging

    lgdt [gdt64_descriptor]
    call enable_long_mode
    jmp 0x08:long_mode_entry

setup_paging:
    mov edi, 0x1000
    xor eax, eax
    mov ecx, 5 * 4096 / 4
    rep stosd

    ; *IMPORTANT*
    ; Identity map first 2MB
    ; Map 0x0000000000000000-0x00000000001fffff
    ; to physical 0x00000000-0x001fffff
    mov dword [0x1000], 0x00002003  ; PML4[0] = 0x2000 | PRESENT | READWRITE
    mov dword [0x2000], 0x00003003  ; PDP[0]  = 0x3000 | PRESENT | READWRITE
    mov dword [0x3000], 0x00000083  ; PD[0]   = 0x0000 | PRESENT | READWRITE | 2MB_PAGE

    ; Map 0xFFFFFFFF80000000-0xffffffff801fffff
    ; to physical 0x00000000-0x001fffff
    mov dword [0x1000 + 8 * ((KERNEL_OFFSET_HIGH >> 39) & 0x1FF)], 0x00004003    ; PML4[511] = 0x4000 | PRESENT | READWRITE
    mov dword [0x4000 + 8 * ((KERNEL_OFFSET_HIGH >> 30) & 0x1FF)], 0x00005003    ; PDP[510]  = 0x5000 | PRESENT | READWRITE
    mov dword [0x5000 + 8 * ((KERNEL_OFFSET_HIGH >> 21) & 0x1FF)], 0x00000083    ; PD[0]     = 0x0000 | PRESENT | READWRITE | 2MB_PAGE

    mov edi, 0x1000
    mov cr3, edi
    ret

enable_long_mode:
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, 10100000B
    mov cr4, eax

    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    ret

[BITS 64]
long_mode_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, 0x90000 + KERNEL_OFFSET_HIGH

    mov rsi, longModeMessage
    call print_long_mode

    mov rax, KERNEL_OFFSET_HIGH + KERNEL_OFFSET_LOW
    jmp rax

[BITS 16]
print_16bit:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_16bit
.done:
    ret

[BITS 32]
print_protected_mode:
    push eax
    push ebx
    mov ebx, VGA_MEMORY
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0F
    mov [ebx], ax
    add ebx, 2
    jmp .loop
.done:
    pop ebx
    pop eax
    ret

[BITS 64]
print_long_mode:
    push rax
    push rbx
    mov rbx, VGA_MEMORY
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0F
    mov [rbx], ax
    add rbx, 2
    jmp .loop
.done:
    pop rbx
    pop rax
    ret

[BITS 16]
disk_error:
    mov si, diskErrorMessage
    call print_16bit
    cli
    hlt

stage2Message db 'Jumped to stage 2', 13, 10, 0
diskErrorMessage db 'Disk error in stage 2', 13, 10, 0
longModeMessage db 'Entered long mode', 0
protectedModeMessage db 'Entered protected mode', 0

align 16
gdt_start:
    dq 0x0000000000000000           ; null descriptor
    dq 0x00CF9A000000FFFF           ; 32-bit code descriptor
    dq 0x00CF92000000FFFF           ; 32-bit data descriptor
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

gdt64_start:
    dq 0x0000000000000000           ; null descriptor
    dq 0x00AF9A000000FFFF           ; 64-bit code descriptor
    dq 0x00AF92000000FFFF           ; 64-bit data descriptor
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dq gdt64_start
