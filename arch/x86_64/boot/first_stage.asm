[BITS 16]
[ORG 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    mov ax, 0x0203      ; ah = 02 (read), al = 3 (sectors)
    mov cx, 0x0002      ; ch = 0 (cylinder), cl = 2 (sector)
    xor dh, dh          ; head 0 - faster than mov dh, 0
    mov bx, 0x7E00      ; 2nd stage bootloader buffer address
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    mov si, succ_msg
    call printf

    db 0xEA
    dw 0x0000, 0x07E0

disk_error:
    mov si, disk_error_msg
    call printf
    mov al, ah          ; Save error code
    call get_hex
    cli
.hlt:
    hlt
    jmp short .hlt

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
    mov dl, al         ; Save original
    shr al, 4          ; High nibble
    call print_nibble
    mov al, dl
    and al, 0x0F       ; Low nibble
    call print_nibble
    pop ax
    ret

print_nibble:
    and al, 0x0F
    add al, '0'        ; ascii conversion
    cmp al, '9'
    jbe .print         ; if it's 0-9, print it
    add al, 7          ; otherwise convert to A-F
.print:
    mov ah, 0x0E
    int 0x10
    ret

boot_drive:    db 0
succ_msg:      db "OK", 0
disk_error_msg:db "ERR:", 0

times 510-($-$$) db 0
dw 0xAA55
