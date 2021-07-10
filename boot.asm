boot_loader:
    .setup:
        ; Set up ds segment
        mov ax, 0x07c0
        mov ds, ax
        mov es, ax

        ; Temporary stack
        mov bp, 0xf000
        mov sp, bp

    .load_sectors:
        mov bx, 0x0200

        mov ah, 0x02
        mov al, 0x34 ; 52 sectors
        mov ch, 0
        mov cl, 0x02
        mov dh, 0
        ; dl already set
        int 0x13

        jc disk_error
        cmp al, 0x34
        jne disk_error

        push success_msg
        call _print_str
        add sp, 2

        push start_msg
        call _print_str
        add sp, 2

        push word 1000
        call _sleep
        add sp, 2

    .draw_setup:
        mov cx, 0
    .draw_loop:
        call _clear
        push cx
        mov ax, 8
        mul cx
        push ax
        call _print_frame
        add sp, 2
        push word 45
        call _sleep
        add sp, 2
        pop cx
        inc cx
        cmp cx, [frames_count]
        jne .draw_loop

        push end_msg
        call _print_str

hang:
        jmp hang

disk_error:
        push ax
        call _print_hex
        push disk_error_msg
        call _print_str
        jmp hang
a20_error:
        push a20_error_msg
        call _print_str
        jmp hang

; void clear(void);
_clear:
        mov ax, 0x0f00
        int 0x10
        mov ah, 0x00
        int 0x10
        ret

; void sleep(unsigned short millis);
_sleep:
        push bp
        mov bp, sp
        mov ax, [bp+4]
        mov bx, 1000
        mul bx
        mov cx, dx
        mov dx, ax
        mov ax, 0x8600
        int 0x15
        pop bp
        ret

; void print_frame(unsigned short line);
_print_frame:
        push bp
        mov bp, sp
        push si
        mov si, [bp+4]
        add si, frames
        mov cx, 8
    .next_line:
        push cx
        lodsb
        mov ah, 0
        push ax
        call _print_line
        add sp, 2
        pop cx
        loop .next_line
    .end_frame:
        pop si
        pop bp
        ret

; void print_line(unsigned char line);
_print_line:
        push bp
        mov bp, sp
        push si
        mov cx, 8
    .next_bit:
        mov si, symbol_src
        mov ax, [bp+4]
        rol al, 1
        mov [bp+4], ax
        and ax, 1
        add si, ax
        mov ah, 0x0e
        mov al, [si]
        mov bx, 0
        int 0x10
        loop .next_bit
    .end_line:
        call _print_nl
        pop si
        pop bp
        ret

; void print_nl(void);
_print_nl:
        mov ax, 0x0e0a
        int 0x10
        mov ax, 0x0e0d
        int 0x10
        ret

; void print_str(char *buffer);
_print_str:
        push bp
        mov bp, sp
        push si
        mov si, [bp+4]
    .next_char:
        mov ah, 0x0e
        mov al, [si]
        cmp al, 0
        jz .end_str
        int 0x10
        inc si
        jmp .next_char
    .end_str:
        pop si
        pop bp
        ret

; void print_hex(unsigned short num);
_print_hex:
        push bp
        mov bp, sp
        push si
        mov cx, 0
    .next_digit:
        mov dx, 0
        mov ax, [bp+4]
        mov bx, 16
        div bx
        mov [bp+4], ax
        push dx
        inc cx
        cmp word [bp+4], 0
        ja .next_digit
    .print_digit:
        pop si
        add si, hex_src
        lodsb
        mov ah, 0x0e
        int 0x10
        loop .print_digit
    .end_hex:
        pop si
        pop bp
        ret

        disk_error_msg db "There was error reading the disk!", 10, 13, 0
        a20_error_msg db "A20 line could not be enabled!", 10, 13, 0
        success_msg db "Set up finished successfuly!", 10, 13, 0
        start_msg db "Playing Bad Apple...", 10, 13, 0
        end_msg db "Animation finished!", 10, 13, 0
        hex_src db "0123456789ABCDEF"
        symbol_src db " #"
        frames_count dw 3286
        times 510-($-$$) db 0
        dw 0xAA55

%include "frames.inc"
