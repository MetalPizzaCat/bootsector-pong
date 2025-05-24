org 0x7c00                          ; The entry address to copy the code to;
                                    ; this changes when setting it to run from boot sector

start:

    mov ax, 0x13                    ; enable 320 x 200 x 8 video mode
    int 0x10

    mov ax, screen.address          ; set the video mem address
    mov es, ax

game:
clr_scr:
    mov di, screen.w * screen.h     ; screen size
    .loop:
    mov byte [es:di], 0
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
    mov dl, player1.color
    mov cx, player_base.size
    call draw_box

    mov ax, player2.x
    mov bx, [player2.y]
    mov dl, player2.color
    mov cx, player_base.size
    call draw_box

draw_scores:
    mov dx, player1.score_pos
    mov al, [player1.score]
    add al, '0'
    mov bl, player1.color
    call plot_char

    mov dx, player2.score_pos
    mov al, [player2.score]
    add al, '0'
    mov bl, player2.color
    call plot_char


update_player:
    in al, keyboard.port                     ; read the keyboard input
    cmp al, keyboard.start
    jne .check_movement
    mov byte [ball.moving], 1
    jmp .end
    .check_movement:
        cmp al, keyboard.up
        je .move_up
        cmp al, keyboard.down
        je .move_down
        jmp .end
    
        .move_up:
            mov ax, [player1.y]
            test ax, ax
            jz .end
            dec word [player1.y]
            jmp .end
        .move_down:
            mov ax, [player1.y]
            add ax, player_base.h
            cmp ax, screen.h
            je .end
            inc word [player1.y]
    .end:

update_ai:
    mov cx, [ball.x]
    cmp cx, player2.reach           ; check if ball is close enough that paddle should move
    jle .end
    mov cx, [player2.y]             ; check if ball is below or above the paddle
    cmp cx, [ball.y]                
    jg .move_up
    add cx, player_base.h
    cmp cx, [ball.y]                ; account for the size of the paddle when checking if below
    jl .move_down
    jmp .end

    .move_up:
        dec word [player2.y]
        jmp .end
    .move_down:
        inc word [player2.y]
    .end:

    

update_ball:
    mov al, [ball.moving]
    test al, al
    jz end_ball_update

update_x:
    mov ax, [ball.x]
    mov bx, [ball.x_dir]
    add ax, bx                      ; apply speed
    jz score.ai                     ; if it ends up being 0, we consider it touching on left side
    
    cmp ax, screen.w                ; check if it reached right side of the screen
    je score.player

    mov dx, ax                      ; save ax value, because we will be modifying it
    .collide_p1:
        sub ax, player_base.w       ; subtract paddle width from ball position to account for paddle width
        cmp ax, player1.x
        jne .collide_p2             ; if it doesn't touch, we ignore
        mov cx, [player1.y]         ; check if ball is above the paddle
        cmp cx, [ball.y]
        jg .collide_p2
        add cx, player_base.h       ; check if ball is below the paddle
        cmp cx, [ball.y]
        jge .bounce
    .collide_p2:
        mov ax, dx                  ; restore ball pos 
        add ax, ball.w              ; add ball width to check ball right side collision
        cmp ax, player2.x
        jne .end
        mov cx, [player2.y]         ; check if ball is above the paddle
        cmp cx, [ball.y]
        jg .end
        add cx, player_base.h       ; and check if below the paddle
        cmp cx, [ball.y]
        jl .end
    
    .bounce:
        neg word [ball.x_dir]
    .end:
        mov [ball.x], dx

update_y:
    mov ax, [ball.y]                ; load y into ax
    mov bx, [ball.y_dir]            ; and speed into bx
    add ax, bx                      ; apply the speed
    jz .bounce                      ; if result of addition is 0, bounce because we hit the top
    cmp ax, screen.h
    jne .end
    .bounce:
        neg bx                      ; just flip the speed
        mov [ball.y_dir], bx
    .end:
        mov [ball.y], ax
    end_ball_update:

frame_delay:
    mov ah, 0x86                    ; elapsed time wait call
    mov cx, 0                       ; delay
    mov dx, screen.frame_delay      ; delay
    int 0x15                        ; call the delay
    

    jmp game
.spin:
    jmp .spin                       ; Spin forever

score:
    .player:
        inc byte [player1.score]
        jmp .end
    .ai:
        inc byte [player2.score]
    .end:
        mov byte [ball.moving], 0 
        mov word [ball.x], ball.start_x
        mov word [ball.y], ball.start_y
        neg word [ball.x_dir]
    jmp frame_delay


; al - char
; bl - color
; dl - x
; dh - y
plot_char:
    mov bh, 0                   ; page zero
    push ax
    push bx
    mov ax, 0x200               ; move cursor
    int 0x10
    pop bx
    pop ax
    mov ah, 0xa                 ; plot character
    mov cx, 1                   ; repeat once
    int 0x10
    ret
    
; ax = x, bx = y, dl = color, ch - w, cl - h
draw_box:
    mov [draw_box_data], cx
    xor cx, cx
    mov cl, [draw_box_data.w]
    .loop_horizontal:
        push bx
        push cx
        mov cl, [draw_box_data.h]
        .loop_vertical:
            ; plot a pixel with ax = x, bx = y, dl = color
            .plot:
                push bx
                imul bx, screen.w               ; i = y * width + x
                mov di, ax
                add di, bx                     
                mov [es:di], dl                 ; move at di value dl using the offset
                pop bx
            inc bx
            loop .loop_vertical
        pop cx
        inc ax
        pop bx
    loop .loop_horizontal
    ret

draw_box_data:                              ; variables used during the drawing process
    .w db 0                                 ; backup of the width
    .h db 0                                 ; backup of the height


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
    .x dw .start_x
    .y dw .start_y
    .start_x equ (screen.w - ball.w) / 2
    .start_y equ (screen.h - ball.h) / 2
    .y_dir dw 1
    .x_dir dw 1
    .moving db 0



player1:
    .x equ player_base.dist_x
    .y dw (screen.h - player_base.h) / 2
    .score db 0
    .score_x equ 1
    .score_y equ 3
    .score_pos equ (.score_y << 8) | .score_x
    .color equ 14

player2:
    .x equ screen.w - player_base.dist_x
    .y dw (screen.h - player_base.h) / 2
    .score db 0
    .reach equ 200
    .score_x equ 38
    .score_y equ 3
    .score_pos equ (.score_y << 8) | .score_x
    .color equ 13

keyboard:
    .port equ 0x60              ; keyboard port 
    ; these are scan codes for the keys
    .up equ 0x11                ; w
    .down equ 0x1f              ; s
    .start equ 0x39             ; space

padding:
        %assign compiled_size $-$$
        %warning Compiled size: compiled_size bytes
        
times 510-(compiled_size) db 0x4f
db 0x55, 0xaa                   ; bootable signature