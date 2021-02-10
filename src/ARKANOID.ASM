; ========================================================================
; House-DOS Arkanoid Game
; 
; Written by Jet & Jacob
; ========================================================================

    BITS 16

; ========================================================================
; Main code
; ========================================================================

start:
    
    mov AH, 0x03                        ;confirmation to start the game
    int 0x7E                            ;Call SYS.BIN
    jc quit                             ;quit the game if the confirmation is denied

    call updateBlocks
    
pause:
    call onesec

main:

;turn off speaker
    mov AH, 0xc3
    int 0x7E



check_reflect:

;walls

.leftwall:
    cmp byte [ballx], 0x01
    jg .rightwall

    mov byte [ballvelx], 0x01

.rightwall:
    cmp byte [ballx], 0x4e
    jl .topwall

    mov byte [ballvelx], 0xFF

.topwall:
    cmp byte [bally], 0x00
    jne .bottomwall

    mov byte [ballvely], 0x00
    jmp keypress

.bottomwall:
    cmp byte [bally], 0x30
    jne .paddle
    jmp loselife

.processwallside:
    xor byte [ballvelx], 0b10000000

.paddle:                                 ;ball hit paddle go *bong*
    cmp byte [bally], 0x28                  ;is the ball next to the paddle?
    jne .bricks                             ;if not, skip
    cmp byte [ballvely], 0x00               ; is the ball going down?
    jne keypress                            ; if not, skip this and skip bricks because we already know we're nowhere near the bricks
    mov AL, byte [padpos]                   ; load the paddle position
    cmp AL, byte [ballx]                    ; setting the greater than and equal to flags
    jg keypress                             ;if the ball is less than the paddle, skip
    add AL, 0x0c                            ; finsing the right end of the paddle
    cmp AL, byte [ballx]                    ; setting the greater than and equal to flags
    jle keypress                            ; if the ball is to the right of the paddle, skip

    mov byte [ballvely], 0x01               ;ball go up
    mov AH, 0xa0                            ;getting a kinda random number
    int 0x7E                        
    shr DX, 0x0E                            ;make the random number an int
    dec DL                                  ;get the possible ints in the range [-1, 2]
    mov byte [ballvelx], DL                 ;set the ballvelx to that random number. this make sthe game spicier

    jmp keypress

.bricks:

    ;create_masks
    mov AL, byte [ballx]                ;moving the ballx into a register for division
    mov AH, 0x00                        ;clearing the upper byte of AX
    mov DL, 0x05                        ;putting the divisor into DL
    div DL                              ;diving the ballx by 5 to get the position of the brick in the brick row
    
    mov CL, AL
    mov DX, 0x01                        ;preparing to create the mask
    shl DX, CL                          ;createing the mask for finding the brick by shifting 1 AL number of times
    mov Bx, DX
    not BX                              ;finding the anti mask for getting rid of bricks

    mov SI, row5                        ;the counter for the addresses of the rows
    mov CX, 5                           ;the counter for the loop

    cmp byte [ballvely], 0x00           ;check if the ball is going down
    je .check_row5_top                  ; if it is, check the top side of the bricks

.check_rows_bottom:
    mov AX, word [SI]                   ;load row SI
    and AX, DX                          ;and the mask and the row to check if there is a brick in the mask position
    cmp AX, 0x00                        ;check if the and resulted in there not being a brick there
    jne .rows_bottom                    ;if there was a brick there, jump

.next_row_bottom:
    sub SI, 0x0002                      ; change the address of SI to the next row
    loop .check_rows_bottom             ; loop to the next row
    jmp keypress

.check_rows_top:
    mov AX, word [SI]                   ;load row SI
    and AX, DX                          ;and the mask and the row to check if there is a brick in the mask position
    cmp AX, 0x00                        ;check if the and resulted in there not being a brick there
    jne .rows_top                    ;if there was a brick there, jump

.next_row_top:
    sub SI, 0x0002                      ; change the address of SI to the next row
    loop .check_rows_top             ; loop to the next row
    jmp keypress

.rows_bottom:
    mov AX, CX
    shl AX, 0x01
    add AX, 0x08

    cmp byte [bally], AX              ;check if the ball is right under the row
    jne .next_row_bottom              ;if it is not, check the next row
    mov byte [ballvely], 0x00           ;have the ball go down because the ball had to have gone up to get to the bottom
    and word [SI], BX                 ;remove the brick the ball hit using the anti mask
    jmp noise                           ;make a sound

.rows_top:
    mov AX, CX
    shl AX, 0x01
    add AX, 0x04

    cmp byte [bally], AX              ;check if the ball is right under the row
    jne .next_row_top              ;if it is not, check the next row
    mov byte [ballvely], 0x00           ;have the ball go down because the ball had to have gone up to get to the bottom
    and word [SI], BX                 ;remove the brick the ball hit using the anti mask
    jmp noise                           ;make a sound

noise:
.clearBlock:
    mov AL, byte [ballx]                ;moving the ballx into a register for division
    mov AH, 0x00                        ;clearing the upper byte of AX
    mov DL, 0x05                        ;putting the divisor into DL
    div DL                              ;diving the ballx by 5 to get the position of the brick in the brick row
    
    mov DL, AL                          ;
    shl DL, 0x02                        ; multiplying 4 to BH
    add DL, AL                          ; adding its self to total a mult x5

    mov AH, 0x11                        ;create the block
    mov AL, 0xdb                        ;set the character to block
    mov BL, 0x00                        ;black         
    mov CX, 0x04                        ;setting the block length to 4
    int 0x7E                            ;Call SYS.BIN

    mov AH, 0xC2                        ; make asound
    mov DX, 0x120                       ;audable sound
    int 0x7E

keypress:

    mov AH, 0x12                        ;non-blocking keygrabber
    int 0x7E                            ;noone cares
    jc UpdateBall                    ; if there was no keypress skip

    cmp AH, 0x4b                        ; if left arrow has been pressed
    je .left

    cmp AH, 0x4d                        ; if right arrow has been pressed
    je .right

    cmp AH, 0x39                        ; if pause has been pressed
    je .pause

    cmp AH, 0x01                        ; if escape has been pressed
    je quit

.left:
    cmp byte [padpos], 0x00             ;if padpos is already at left wall, skip
    je UpdateBall
    sub byte [padpos], 0x02             ;move the padpos to the left
    jmp UpdateBall

.right:
    cmp byte [padpos], 0x44             ;if padpos is already at right wall, skip
    je UpdateBall
    add byte [padpos], 0x02             ;move the padpos to the right
    jmp UpdateBall

.pause:
    mov AH, 0x12                        ;non-blocking keygrabber
    int 0x7E                            ;noone cares
    jc .pause                           ; if there was no keypress skip


UpdateBall:
    mov AH, 0x11                        ;create the smiley
    mov AL, 0x01                        ;set the character to smiley
    mov BL, 0x00                        ;setting the colour to white
    mov DL, byte [bally]                ;setting the row number
    mov DH, 0x00                        ;clearing the upper byte
    shr DX, 0x1                         ;precision dip 
    mov DH, DL
    mov DL, byte [ballx]                ;setting the column number
    mov CX, 0x01                        ; setting the block length to 1
    int 0x7E                            ;Call SYS.BIN


    mov AL, byte [ballvelx]                 ;loading one of the operands
    add byte [ballx], AL                    ;adding ball vel x to ball x

    cmp byte [ballvely], 0x01               ;if ball vel is positive
    je .subbally                            

    inc byte [bally]                     ;if ball velocity is up move up
    jmp .drawball

.subbally:
    dec byte [bally]                     ;if ball velocity is down move down

.drawball:
    mov AH, 0x11                        ;create the smiley
    mov AL, 0x01                        ;set the character to smiley
    mov BL, 0x0F                        ;setting the colour to white
    mov DL, byte [bally]                ;setting the row number
    mov DH, 0x00                        ;clearing the upper byte
    shr DX, 0x1                         ;precision dip 
    mov DH, DL
    mov DL, byte [ballx]                ;setting the column number
    mov CX, 0x01                        ; setting the block length to 1
    int 0x7E                            ;Call SYS.BIN

updatePaddle:

    mov AH, 0x11                        ;create the smiley
    mov AL, 0xdb                        ;set the character to block
    mov BL, 0x00                        ;setting the colour to white
    mov DL, 0x00                        ;setting the column number
    mov DH, 0x15                        ;setting the row number
    mov CX, 0x50                        ; setting the block length to 12
    int 0x7E                            ;Call SYS.BIN

    mov AH, 0x11                        ;create the smiley
    mov AL, 0xdb                        ;set the character to block
    mov BL, 0x0F                        ;setting the colour to white
    mov DL, byte [padpos]               ;setting the column number
    mov DH, 0x15                        ;setting the row number
    mov CX, 0x0c                        ; setting the block length to 12
    int 0x7E                            ;Call SYS.BIN

next_frame:
    mov AH, 0xc1                        ;sleep hz
    mov BX, 0x0014                      ;20 hz
    mov CX, 0x001                       ;1 frame every 20 herz
    int 0x7E                            ;Call SYS.BIN
    jmp main                            ;start the next frame


; ========================================================================
; Routines
; ========================================================================


updateBlocks:
    pusha
    mov AH, 0x06                       ;clearing the screen
    int 0x7E                            ;Call SYS.BIN

    mov AX, word [row1]                 ;setting the row to row1
    mov BL, 0x04                        ;setting the colour to red
    mov BH, 0x04                        ;setting the row to 4
    call checkRow                       ;displaying row1


    mov AX, word [row2]                        ;setting the row to row2
    mov BL, 0x0E                        ;setting the colour to yellow
    mov BH, 0x05                        ;setting the row to 5
    call checkRow                       ;displaying row2


    mov AX, word [row3]                 ;setting the row to row3
    mov BL, 0x02                        ;setting the colour to green
    mov BH, 0x06                        ;setting the row to 6
    call checkRow                       ;displaying row3


    mov AX, word [row4]                 ;setting the row to row4
    mov BL, 0x03                        ;setting the colour to cyan
    mov BH, 0x07                        ;setting the row to 7
    call checkRow                       ;displaying row4


    mov AX, word [row5]                 ;setting the row to row5
    mov BL, 0x01                        ;setting the colour to blue
    mov BH, 0x08                        ;setting the row to 8
    call checkRow                       ;displaying row5
    popa 
    ret

quit:
    mov AH, 0x06                        ;clearing the screen
    int 0x7E                            ;Call SYS.BIN
    mov AH, 0xFF                        ;quit the game
    int 0x7e                            ;Call SYS.BIN

loselife:
    cmp byte [lives], 0x01              ; do we have 1 life?
    je quit                             ; if so, wuit the game

.reset:                                  ; if we have more than 1 lives, decrement and resent the game
    dec byte [lives]                    

    ;set ball
    mov byte [ballx], 0x28     ;the ball's x position
    mov byte [bally], 0x28     ;the ball's y position

    mov byte [ballvelx], 0x00     ;the ball's x velocity
    mov byte [ballvely], 0x01     ;the ball's y position

    ;set paddle
    mov byte [padpos], 0x20     ;leftmost column of the paddle

    jmp pause
    
onesec:
    pusha
    mov AH, 0xc0
    mov CX, 0x3e8
    int 0x7e
    popa
    ret
    
checkRow:                               ;AX is the row's stuff, Bl is the color, BH is the row the Bricks will be made on 
    pusha                               ;saving all the registries
    mov CX, 0x10                         ;counter for &bit and x

.check:
    push CX                             ; saving the counter
    push AX                             ;we're going to be using this later
    dec CX                              ;decrement CX by 1

    mov DX, 0x01                        ; putting DX as 1
    shl DX, CL                          ; Creating the 2byte mask for checking row esc. 0001000000000000 (16 bits)
    and AX, DX                          ; anding the mask and the row, checking if there is a brick
    jz .repeat                          ; if there is no brick where we checked, dont run the summon brick things
    
    mov Al, 0x05                        ;setting one factor to 5
    mul CL                              ; multiplying the counter by 5
    mov DL, AL                          ; Finding the collum number of the brick and setting it for the summoning of the brick ahhhh

    mov AH, 0x11                        ;create the block
    mov AL, 0xdb                        ;set the character to block
    ; bl is the color which is already set
    mov DH, BH                          ; setting the row number
    mov CX, 0x04                        ; setting the block length to 4
    int 0x7E                            ;Call SYS.BIN

.repeat:
    pop AX
    pop CX                              ;restore counter
    loop .check

.donebricks:
    popa                                ;restore all the registries
    ret                                 ;return to the line of calling



data:

lives       db 0x3     ;the lives

padpos      db 0x18     ;leftmost column of the paddle

ballx       db 0x28     ;the ball's x position
bally       db 0x28     ;the ball's y position

ballvelx    db 0x00     ;the ball's x velocity
ballvely    db 0x01     ;the ball's y position

row1        dw 0xFFFF     ;row one of bricks
row2        dw 0xFFFF     ;row one of bricks
row3        dw 0xFFFF     ;row one of bricks
row4        dw 0xFFFF     ;row one of bricks
row5        dw 0xFFFF     ;row one of bricks
