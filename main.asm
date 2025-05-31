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
    mov byte [es:di], 0             ; write black pixels
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
    add al, '0'                                     ; adding '0' will convert integer in range 0-9 to an ascii value
                                                    ; note that this will print nonsense with values out of that range
    mov bl, player2.color
    call plot_char

show_game_over:
    mov al, [end_game.is_game_over]
    test al, al                                    ; check if is_game_over == false
    jz .end
        mov di, end_game.msg
        mov cx, end_game.size
        mov dl, end_game.x
        mov dh, end_game.y
        mov bl, 12                                  ; use color #12 cause i felt like it
        .print:
            mov al, [di]                            ; load character in string. al = *str
            push cx                                 ; plot char uses cx so we need to preserve it
            call plot_char
            pop cx
            inc dl                                  ; x++
            inc di                                  ; str++
            loop .print
        .check_reset:
            in al, keyboard.port                    ; read the keyboard input
            cmp al, keyboard.start                  ; check if space is currently held and if so, run the reset program
            je score_reset
        jmp frame_delay
    .end:


update_player:
    in al, keyboard.port                            ; read the keyboard input
    cmp al, keyboard.start                          ; check if space is held 
    jne .check_movement
    mov byte [ball.moving], 1                       ; set ball.moving = true, does nothing if ball is moving
    jmp .end
    .check_movement:
        cmp al, keyboard.up
        je .move_up
        cmp al, keyboard.down
        je .move_down
        jmp .end
    
        .move_up:
            mov ax, [player1.y]
            test ax, ax                             ; test if player1.y == 0, if true, don't move
            jz .end
            dec word [player1.y]                    ; otherwise player1.y -= 1, 0 is top in this case
            jmp .end
        .move_down:
            mov ax, [player1.y]                     ; load y again
            add ax, player_base.h                   ; but also add height of the paddle
            cmp ax, screen.h                        ; check if bottom of the paddle touches the end of the screen
            je .end
            inc word [player1.y]                    ; if doesn't, increase y
    .end:

update_ai:
    mov cx, [ball.x]
    cmp cx, player2.reach                           ; check if ball is close enough that paddle should move
    jle .end
    mov cx, [player2.y]                             ; check if ball is below or above the paddle
    cmp cx, [ball.y]                
    jg .move_up
    add cx, player_base.h
    cmp cx, [ball.y]                                ; account for the size of the paddle when checking if below
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
    add ax, [ball.x_dir]            ; apply speed
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
    add ax,  [ball.y_dir]                      ; apply the speed
    jz .bounce                      ; if result of addition is 0, bounce because we hit the top
    cmp ax, screen.h
    jne .end
    .bounce:   
        neg word [ball.y_dir]       ; just flip the speed
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
        jmp .check_score
    .ai:
        inc byte [player2.score]
    .check_score:
        cmp byte [player1.score], end_game.max_score
        jne .check_score_p1
        mov byte [end_game.is_game_over], 1
    .check_score_p1:
        cmp byte [player2.score], end_game.max_score
        jne .end
        mov byte [end_game.is_game_over], 1
    .end:
        mov byte [ball.moving], 0 
        mov word [ball.x], ball.start_x
        mov word [ball.y], ball.start_y
        neg word [ball.x_dir]
        
    jmp frame_delay

; reset the current score and disable the game end screen
score_reset:
    mov byte [player1.score], 0
    mov byte [player2.score], 0
    mov byte [end_game.is_game_over], 0
    mov word [player1.y], player_base.start_y
    mov word [player2.y], player_base.start_y
    jmp score.end

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

; single function that can draw a filled box of a given color
; ax = x, bx = y, dl = color, ch - w, cl - h
draw_box: 
    mov dh, cl                                      ; preserve width because it resets each line
    mov di, bx
    imul di, screen.w
    add di, ax                                      ; calculate starting x as x + y * width
    .vert:
        mov cl, dh
        push di                                     ; save to know what value we start at
        .hor:
            mov [es:di], dl                         ; write the pixel data
            inc di                                  ; advance graphics
            dec cl                                  ; reduce counter
        jnz .hor
    pop di                                          ; restore graphics pointer
    add di, screen.w                                ; y++, to avoid recalculating whole coordinate
    dec ch
    jnz .vert
    .end:
    ret

end_game:
    .msg db "Game over!"
    .size equ $ - .msg
    .x equ (40 - .size) / 2
    .y equ 12
    .c equ 10
    .is_game_over db 0
    .max_score equ 9

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
    .start_y equ (screen.h - player_base.h) / 2

ball:
    .w equ 4
    .h equ 4
    .size equ (.h << 8) | (.w)                          ; calculate the full size in a way that can put into cx
    .x dw .start_x
    .y dw .start_y
    .start_x equ (screen.w - ball.w) / 2
    .start_y equ (screen.h - ball.h) / 2
    .start_pos equ (.start_x << 8) | .start_y
    .y_dir dw 1
    .x_dir dw 1
    .moving db 0



player1:
    .x equ player_base.dist_x
    .y dw player_base.start_y
    .score db 0
    .score_x equ 1
    .score_y equ 3
    .score_pos equ (.score_y << 8) | .score_x
    .color equ 14

player2:
    .x equ screen.w - player_base.dist_x
    .y dw player_base.start_y
    .score db 0
    .reach equ 180
    .score_x equ 38
    .score_y equ 3
    .score_pos equ (.score_y << 8) | .score_x                   ; combining values into one will make it easier to load both in 16bit register in one instruction
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