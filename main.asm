org 0x7c00                      ; The entry address to copy the code to;
                                ; this changes when setting it to run from boot sector

start:
    mov ax, 0x0002              ; Set 80-25 text mode
    int 0x10

    mov ax, 0xb800              ; Segment for the video data
    mov es, ax
    cld

    ; Game title
    mov ah, 0x67                ; Background: brown; Foreground: Light gray
    mov bp, title_string        ; Copying the address to the text
    mov cx, 62                  ; 62 => (0, 31)
    call print_string

    push 0x3800
    push 0x1125
    push 44
    push 160 * 5
    call draw_box
exit:
    int 0x20


;
; Draw box function
; Params:   [bp+2] - row offset
;           [bp+4] - column offset
;           [bp+6] - box dimensions
;           [bp+8] - char/Color
;
draw_box:
    mov bp, sp                      ; Store the base of the stack, to get arguments
    xor di, di                      ; Sets DI to screen origin
    add di, [bp+2]                  ; Adds the row offset to DI

    mov dx, [bp+6]                  ; Copy dimensions of the box
    mov ax, [bp+8]                  ; Copy the char/color to print
    mov bl, dh                      ; Get the height of the box

    xor ch, ch                      ; Resets CX
    mov cl, dl                      ; Copy the width of the box
    add di, [bp+4]                  ; Adds the line offset to DI
    rep stosw

    add word [bp+2], 160            ; Add a line (180 bytes) to offset
    sub byte [bp+7], 0x01           ; Remove one line of height - it's 0x0100 because height is stored in the msb
    mov cx, [bp+6]                  ; Copy the size of the box to test
    cmp ch, 0                       ; Test the height of the box
    jnz draw_box                    ; If not zero, draw the rest of the box
    ret


;
; Print string function
; Params:   AH - background/foreground color
;           BP - string addr
;           CX - position/offset
;
print_string:
    mov di, cx                      ; Adds offset to DI
    mov al, byte [bp]               ; Copies the char to AL (AH already contains color data)
    cmp al, 0                       ; If the char is zero, string finished
    jz _0                           ; ... return
    stosw
    add cx, 2                       ; Adds more 2 bytes the offset
    inc bp                          ; Increments the string pointer
    jmp print_string                ; Repeats the rest of the string
_0:
    ret

title_string:       db " r e t r o 2 0 4 8 ", 0

times 510-($-$$) db 0x4f
db 0x55, 0xaa                   ; bootable signature