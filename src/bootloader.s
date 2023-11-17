org 0x7c00

mov [drive], dl

xor ax, ax
mov es, ax
mov ds, ax

mov cl, 0x2 ;;kernel_start_sect
mov al, 0x8 ;;kernel_sect_len
mov bx, 0x1000 ;;kernel_addr
call loadSect

mov cl, 0x0a ;;storage_start_sect
mov al, 0x11 ;;storage_sect_len
mov bx, 0x2000 ;;storage_addr
call loadSect

jmp 0x1000

printstr:
.loop:
    lodsb
    cmp al, 0x00
    je .done
    mov ah,0x0e
    mov bx,0x00
    int 0x10
    jmp .loop
.done:
    ret

loadSect:
    xor dx, dx
    mov es, dx
    mov ch, 0x00
    mov dh, 0x00
    mov dl, [drive]
    mov ah, 0x02
    int 0x13
    jnc .done
    mov si, load_err
    call printstr
    jmp halt
.done:
    ret

halt:
    mov si, hlt_msg
    call printstr
    jmp $

load_err: db "Kernel load error", 0x0a, 0x0d, 0x00
hlt_msg: db "System halted", 0x0a, 0x0d, 0x00
drive: db 0x00

section bootword start=0x7dfe
db 0x55, 0xaa
