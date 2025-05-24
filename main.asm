org 0x7c00                          ; The entry address to copy the code to;
                                    ; this changes when setting it to run from boot sector

start:

    mov ax, 0x13                    ; enable 320 x 200 x 8 video mode
    int 0x10

    mov ax, screen.address          ; set the video mem address
    mov es, ax

game:
clr_scr:
    mov cl, 0                       ; clear to black
    mov di, screen.w * screen.h     ; screen size

    .loop:
    mov [es:di], cl
    dec di
    jnz .loop

draw_ball:
    mov ax, [ball.x]                
    mov bx, [ball.y]
    mov dl, 15
    mov cx, ball.size
    call draw_box
draw_players:
    mov ax, player1.x
    mov bx, [player1.y]
    mov dl, 14
    mov cx, player_base.size
    call draw_box

    mov ax, player2.x
    mov bx, [player2.y]
    mov dl, 13
    mov cx, player_base.size
    call draw_box

frame_delay:
    mov ah, 0x86                    ; elapsed time wait call
    mov cx, 0                       ; delay
    mov dx, screen.frame_delay      ; delay
    int 0x15                        ; call the delay
    
    jmp game
.spin:
    jmp .spin                       ; Spin forever


; plot a pixel with ax = x, bx = y, dl = color
plot:
    push bx
    imul bx, screen.w               ; i = y * width + x
    mov di, ax
    add di, bx                     
    mov [es:di], dl                 ; move at di value dl using the offset
    pop bx
    ret
    
; ax = x, bx = y, dl = color, ch - w, cl - h
; used player_base data for width and height
draw_box:
    mov [draw_box_data], cx
    xor cx, cx
    mov cl, [draw_box_data.w]
    .loop_horizontal:
        push bx
        push cx
        mov cl, [draw_box_data.h]
        .loop_vertical:
            call plot
            inc bx
            loop .loop_vertical
        pop cx
        inc ax
        pop bx
    loop .loop_horizontal
    ret

draw_box_data:
    .w db 0
    .h db 0


screen:
    .address equ 0xa000
    .w equ 320
    .h equ 200
    .frame_delay equ 8192

player_base:
    .w equ 4
    .h equ 40
    .size equ (.h << 8) | (.w) 
    .dist_x equ 20

ball:
    .w equ 4
    .h equ 4
    .size equ (.h << 8) | (.w)              ; calculate the full size in a way that can put into cx
    .x dw (screen.w - ball.w) / 2
    .y dw (screen.h - ball.h) / 2



player1:
    .x equ player_base.dist_x
    .y dw (screen.h - player_base.h) / 2
    .score db 0

player2:
    .x equ screen.w - player_base.dist_x
    .y dw (screen.h - player_base.h) / 2
    .score db 0


padding:
        %assign compiled_size $-$$
        %warning Compiled size: compiled_size bytes
        
times 510-(compiled_size) db 0x4f
db 0x55, 0xaa                   ; bootable signature