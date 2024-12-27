[BITS 16]
[ORG 0x7E00]

KERNEL_OFFSET_HIGH  equ 0xFFFFFFFF80000000
KERNEL_LOAD_SEGMENT equ 0x1000
KERNEL_LOAD_OFFSET  equ 0x0000
KERNEL_OFFSET_LOW   equ (KERNEL_LOAD_SEGMENT << 4) + KERNEL_LOAD_OFFSET
VGA_MEMORY         equ 0xB8000

stage2_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    mov si, stage_2_msg
    call printf
    call enable_A20
    call detect_disk_type
    call load_kernel
    call enable_protected_mode

error_handler:
    push ax
    mov si, err_prefix
    call printf
    pop ax
    call get_hex
    cli
.halt:
    hlt
    jmp short .halt

disk_error:
    mov si, disk_msg
    call printf
    mov al, ah
    call get_hex
    cli
.halt:
    hlt
    jmp short .halt

printf:
    pushf
    cld
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp short .loop
.done:
    popf
    ret

get_hex:
    push ax
    mov dl, al
    shr al, 4          ; high nibble
    call print_nibble
    mov al, dl
    and al, 0x0F       ; low nibble
    call print_nibble
    pop ax
    ret

print_nibble:
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jbe .print
    add al, 7
.print:
    mov ah, 0x0E
    int 0x10
    ret

detect_disk_type:
    mov dx, 0x1F7
    in al, dx
    cmp al, 0xFF
    je .use_bios

    mov [disk_mode], byte 1
    ret

.use_bios:
    mov [disk_mode], byte 0
    ret

load_kernel:
    cmp byte [disk_mode], 0
    je load_kernel_bios

    mov edx, 0x1F7
.wait_ready:
    in al, dx
    test al, 0x80     ; bsy
    jnz .wait_ready
    test al, 0x40     ; rdy
    jz .wait_ready

    mov dx, 0x1F2
    mov al, 127
    out dx, al

    mov dx, 0x1F3
    mov al, 5         ; start from sector 5 because 0-4 is our stage 1
    out dx, al

    mov dx, 0x1F4     ; lba
    xor al, al
    out dx, al

    mov dx, 0x1F5     ; LBA high
    out dx, al

    mov dx, 0x1F6     ; device port
    mov al, 0xE0
    out dx, al

    mov dx, 0x1F7     ; cmd port
    mov al, 0x20      ; READ SECTORS command
    out dx, al

    push es
    mov ax, KERNEL_LOAD_SEGMENT
    mov es, ax
    xor di, di          ; ES:DI points to load address

    mov ecx, 127 * 256  ; 256 words per sector
    mov dx, 0x1F0
.read_loop:
    mov dx, 0x1F7
.wait_data:
    in al, dx
    test al, 0x08     ; drq
    jz .wait_data

    mov dx, 0x1F0
    in ax, dx
    mov [es:di], ax
    add di, 2
    loop .read_loop

    pop es
    ret

load_kernel_bios:
    mov ax, KERNEL_LOAD_SEGMENT
    mov es, ax
    xor bx, bx

    mov ah, 0x02      ; BIOS read sectors
    mov al, 127       ; Number of sectors
    mov ch, 0         ; Cylinder 0
    mov cl, 5         ; Start from sector 5
    xor dh, dh        ; Head 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    ret

enable_A20:
    ; try fast A20 first
    in al, 0x92
    test al, 2
    jnz .done
    or al, 2
    and al, 0xFE
    out 0x92, al

    call check_a20
    jnz .done

    ; start keyboard input fallback
    cli
    call .wait_input
    mov al, 0xAD
    out 0x64, al

    call .wait_input
    mov al, 0xD0
    out 0x64, al

    call .wait_output
    in al, 0x60
    push ax

    call .wait_input
    mov al, 0xD1
    out 0x64, al

    call .wait_input
    pop ax
    or al, 2
    out 0x60, al

    call .wait_input
    mov al, 0xAE
    out 0x64, al

    call .wait_input
    sti
.done:
    ret

.wait_input:
    in al, 0x64
    test al, 2
    jnz .wait_input
    ret

.wait_output:
    in al, 0x64
    test al, 1
    jz .wait_output
    ret

check_a20:
    pushf
    push ds
    push es
    push di
    push si

    cli

    xor ax, ax
    mov es, ax

    not ax
    mov ds, ax

    mov di, 0x0500
    mov si, 0x0510

    mov al, byte [es:di]
    push ax

    mov al, byte [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF

    pop ax
    mov byte [ds:si], al

    pop ax
    mov byte [es:di], al

    mov ax, 0
    je .exit

    mov ax, 1

.exit:
    pop si
    pop di
    pop es
    pop ds
    popf

    ret

enable_protected_mode:
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp 0x08:protected_mode_entry

[BITS 32]
protected_mode_entry:
    push 0x10
    pop ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x200000
    mov esi, protected_msg
    call print_protected_mode
    call setup_paging
    lgdt [gdt64_descriptor]
    call enable_long_mode
    jmp 0x08:long_mode_entry

setup_paging:
    mov edi, 0x1000
    xor eax, eax
    mov ecx, 5 * 1024
    rep stosd
    mov eax, 0x2003
    mov [0x1000], eax              ; PML4[0]
    mov eax, 0x3003
    mov [0x2000], eax              ; PDP[0]
    mov dword [0x3000], 0x83       ; PD[0] with 2MB page
    mov eax, 0x4003
    mov [0x1000 + 8 * ((KERNEL_OFFSET_HIGH >> 39) & 0x1FF)], eax
    mov eax, 0x5003
    mov [0x4000 + 8 * ((KERNEL_OFFSET_HIGH >> 30) & 0x1FF)], eax
    mov dword [0x5000 + 8 * ((KERNEL_OFFSET_HIGH >> 21) & 0x1FF)], 0x83
    mov eax, 0x1000
    mov cr3, eax
    ret

enable_long_mode:
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    ret

[BITS 64]
long_mode_entry:
    push 0x10
    pop ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov rsp, 0x90000 + KERNEL_OFFSET_HIGH
    mov rsi, long_msg
    call print_long_mode
    mov rax, KERNEL_OFFSET_HIGH + KERNEL_OFFSET_LOW
    jmp rax

print_protected_mode:
    push rax
    mov rdx, VGA_MEMORY
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0F
    mov [rdx], ax
    add rdx, 2
    jmp short .loop
.done:
    pop rax
    ret

print_long_mode:
    push rax
    mov rdx, VGA_MEMORY
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0F
    mov [rdx], ax
    add rdx, 2
    jmp short .loop
.done:
    pop rax
    ret

section .data
    disk_mode db 0
    boot_drive db 0
    stage_2_msg db 'Stage 2 OK', 13, 10, 0
    disk_msg db 'Disk Error: ', 0
    err_prefix db 'Error Code: ', 0
    long_msg db 'Long Mode OK', 0
    protected_msg db 'Protected Mode OK', 0

align 8
gdt_start:
    dq 0
    dq 0x00CF9A000000FFFF    ; 32-bit code
    dq 0x00CF92000000FFFF    ; 32-bit data
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

align 8
gdt64_start:
    dq 0
    dq 0x00AF9A000000FFFF    ; 64-bit code
    dq 0x00AF92000000FFFF    ; 64-bit data
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dq gdt64_start
