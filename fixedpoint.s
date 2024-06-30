;---------------------------------------------------------------------------------------------------
;  Copyright (c) Peter Bjorklund. All rights reserved. https://github.com/piot/nes-example
;  Licensed under the MIT License. See LICENSE in the project root for license information.
;---------------------------------------------------------------------------------------------------

; Macro that converts a 8.4 fixed point (only used for positions) to the integer part
; it is made as a macro since we have many positions in the game
; and calling each one with a jsr/rts opcode would be too slow.
; A = low part
; Y = high byte
; result will be stored in A
.macro FIXED_TO_INT
    ; Shift the low byte right by 4 bits to get rid of the fraction part
    ; what remains in A should only be the 4 bit integer part AAAA.0000
    lsr a                 ; Shift A right 1 bit
    lsr a                 ; Shift A right 1 bit
    lsr a                 ; Shift A right 1 bit
    lsr a                 ; Shift A right 1 bit

    sta temp

    tya

    ; Now combine with the high byte by rotating into X
    lsr a                 ; Shift A right 1 bit (bit 0 -> Carry)

    rol temp                ; Rotate into X (rotate and set bit 0 from Carry)
    lsr a                 ; Shift A right 1 bit (bit 0 -> Carry)
    rol temp                ; Rotate into X (rotate and set bit 0 from Carry)
    lsr a                 ; Shift A right 1 bit (bit 0 -> Carry)
    rol temp                ; Rotate into X (rotate and set bit 0 from Carry)
    lsr a                 ; Shift A right 1 bit (bit 0 -> Carry)
    rol temp                ; Rotate into X (rotate and set bit 0 from Carry)
    lda temp
.endmacro


.macro FIXED_TO_INT_ADDR addr
    txa
    pha ; save x to be able to restore it later

    ldx addr
    lda addr+1

    FIXED_TO_INT

    tay ; save result in Y
    pla
    tax ; restore x

    tya ; put back result in A

.endmacro