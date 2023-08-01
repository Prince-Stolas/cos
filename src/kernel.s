org 0x1000

storage_space equ 0x08 ;; 8kb
storage_addr equ 0x2000

entry:
    call clear_scr

    mov si, start_msg
    call print_str
    mov ax, storage_space
    call print_dec_int
    mov si, start_msg_space
    call print_str

    call handle_cmds

    jmp $

clear_scr:
    xor ah, ah
    mov al, 0x03
    int 0x10

    mov ah, 0x0b
    xor bh, bh
    xor bl, bl
    int 0x10
    ret

print_char: ;; al=char
    cmp al, 0x0a
    je .linefeed
    cmp al, 0x08
    je .backspace
    cmp al, 0x09
    je .done
    mov cx, 0x01
    mov ah, 0x09
    mov bx, 0x07
    int 0x10
    mov bl, 0x03
    call move_cursor
    jmp .done
.linefeed:
    mov bl, 0x04
    call move_cursor
    jmp .done
.backspace:
    mov bl, 0x02
    call move_cursor
    mov ax, 0x0e20
    int 0x10
    call move_cursor
    jmp .done
.done:
    ret

print_str: ;; si=string
    xor ax, ax
    mov ds, ax
.loop:
    lodsb
    cmp al, 0x00
    je .done
    call print_char
    jmp .loop
.done:
    ret

move_cursor: ;; bl=direction
    mov ah, 0x03
    xor bh, bh
    int 0x10
    cmp bl, 0x00
    je .up
    cmp bl, 0x01
    je .down
    cmp bl, 0x02
    je .left
    cmp bl, 0x03
    je .right
    cmp bl, 0x04
    je .linefeed
    jmp .done
.up:
    dec dh
    jmp .done
.down:
    cmp dh, 0x18
    jne .inc_dh
    push dx
    mov ax, 0x0601
    xor bx, bx
    xor cx, cx
    mov dx, 0x5019
    int 0x10
    pop dx
    jmp .done
.left:
    dec dl
    jmp .done
.right:
    inc dl
    jmp .done
.linefeed:
    xor dl, dl
    jmp .down
.inc_dh:
    inc dh
.done:
    mov ah, 0x02
    int 0x10
    ret

handle_cmd_keyboard: ;; si=cmd di=arg
    push di
    mov di, si
.loop:
    xor ah, ah
    int 0x16
    cmp ah, 0x1c
    je .return
    cmp al, 0x08
    je .backspace
    cmp al, 0x00
    je .done
    call print_char
    xor bx, bx
    mov es, bx
    stosb
    jmp .loop
.return:
    mov al, 0x0a
    call print_char
    call run_cmd
    mov bx, 0x100
    call clear_str
    pop di
    push si
    mov si, di
    mov bx, 0x100
    call clear_str
    mov di, si
    pop si
    jmp .done
.backspace:
    cmp di, si
    je .loop
    dec di
    call print_char
    xor ax, ax
    std
    stosb
    cld
    inc di
    jmp .loop
.done:
    ret

clear_str: ;; si=string, bx=length
    mov di, si
.loop:
    xor ax, ax
    mov es, ax
    stosb
    mov cx, di
    sub cx, si
    cmp cx, bx
    je .done
    jmp .loop
.done:
    ret

string_equ: ;; si=str1 di=str2 : equals_flag=result
    xor bx, bx
.loop:
    mov al, [si+bx]
    mov ah, [di+bx]
    cmp al, 0x00
    je .str1end
    cmp ah, 0x00
    je .unequal
    cmp ah, al
    je .incbx
    jmp .unequal
.incbx:
    inc bx
    jmp .loop
.str1end:
    cmp ah, 0x00
    jne .unequal
.equal:
    mov al, 0x01
    jmp .done
.unequal:
    mov al, 0x00
.done:
    cmp al, 0x01
    ret

run_cmd: ;; si=cmd
    push si
    mov di, arg
    mov bl, 0x00
    call get_argument
    mov si, arg

    mov di, cmd_help
    call string_equ
    je .cmd_help

    mov di, cmd_fs
    call string_equ
    je .cmd_fs

    mov di, cmd_concat
    call string_equ
    je .cmd_concat

    mov di, cmd_love
    call string_equ
    je .cmd_love

    jmp .invalid
.cmd_help:
    mov si, help_msg
    call print_str
    jmp .done
.cmd_fs:
    mov si, storage_addr
    call display_files
    jmp .done
.cmd_concat:
    ;mov si, unimplemented_cmd_msg
    ;call print_str
    mov si, cmd
    mov di, arg
    call concat
    jmp .done
.cmd_love:
    mov si, love_msg
    call print_str
    jmp .done
.invalid:
    mov si, invalid_cmd_msg
    call print_str
.done:
    pop si
    ret

str_to_int:
    ;; kein bock das zu machen
.done:
    ret

concat: ;; si=cmd di=arg_buffer
    push si
    mov si, di
    mov bx, 0x100
    call clear_str
    mov di, si
    pop si
    push si
    push di
    mov bl, 0x01
    call get_argument
    pop di
    mov si, minr_str
    call string_equ
    pop si
    je .reset
    jmp .done
.reset:
    push si
    mov si, di
    mov bx, 0x100
    call clear_str
    mov di, si
    pop si
    mov bl, 0x02
    push di
    call get_argument
    pop di
    mov si, di
    call print_str
.done:
    ret

handle_cmds:
    mov si, cmd
    mov di, arg
.loop:
    mov al, 0x3e
    call print_char
    call handle_cmd_keyboard
    jmp .loop

display_files: ;; si=storage
    xor ax, ax
    mov ds, ax
    xor cx, cx
    mov di, si
.loop:
    xor ax, ax
    mov ds, ax
    lodsb
    inc cx
    add si, ax
    push ax
    push si
    push cx
    mov si, file_str
    call print_str
    pop ax
    call print_dec_int
    push ax
    mov al, 0x20
    call print_char
    pop cx
    pop si
    pop ax
    inc ax
    push cx
    call print_dec_int
    push si
    mov si, kb_str
    call print_str
    mov ax, 0x0a
    call print_char
    pop si
    pop cx
    sub si, di
    mov bx, si
    add si, di
    cmp bx, storage_space
    jne .loop
.done:
    ret

print_dec_int: ;; ax=int
    xor cx, cx
    xor dx, dx
    push ax
    cmp ax, 0x00
    je .print1
.loop:
    cmp ax, 0x00
    je .print
    mov bx, 0x0a
    div bx
    push dx
    inc cx
    xor dx, dx
    jmp .loop
.print:
    cmp cx, 0x00
    je .done
    pop ax
    add ax, 0x30
    push bx
    push cx
    push dx
    call print_char
    pop dx
    pop cx
    pop bx
    dec cx
    jmp .print
.print1:
    mov al, 0x30
    call print_char
.done:
    pop ax
    ret

get_argument: ;; si=cmd di=arg_buffer bl=arg_num
    xor ax, ax
    mov ds, ax
    mov es, ax
.loop:
    cmp ah, bl
    je .return_arg
    lodsb
    cmp al, 0x00
    je .done
    cmp al, 0x20
    jne .loop
    inc ah
    jmp .loop
.return_arg:
    mov di, arg
.loop1:
    lodsb
    cmp al, 0x20
    je .done
    cmp al, 0x00
    je .done
    stosb
    jmp .loop1
.done:
    ret

start_msg: db "COS - Version 0.10", 0x0a, 0x00
start_msg_space: db "kb for files reserved!", 0x0a, 0x00
invalid_cmd_msg:
    db "Invalid command!", 0x0a
    db "Type help for a list of all commands!", 0x0a
    db 0x00
unimplemented_cmd_msg:
    db "This command is not implemented yet!", 0x0a
    db "Try again in the next Version!", 0x0a
    db 0x00
help_msg:
    db "help: Display this prompt", 0x0a
    db "fs: Display all files", 0x0a
    db "concat: Concatonate two or more files to make one bigger file", 0x0a
    db "    Usage:", 0x0a
    db "      concat <options> <file> <num-of-files-to-append>", 0x0a
    db "    Options:", 0x0a
    db "      -r : Reset the concatonations of the file", 0x0a
    db 0x00
love_msg: db "<3", 0x0a, 0x00
file_str: db "File-", 0x00
kb_str: db "kb", 0x00
minr_str: db "-r", 0x00

arg: times 0x100 db 0x00
    
cmd: times 0x100 db 0x00
cmd_fs: db "fs", 0x00
cmd_help: db "help", 0x00
cmd_concat: db "concat", 0x00
cmd_love: db "love", 0x00

times 0x1000-($-$$) db 0x00 ;;kernel rest mit 0x00 füllen
