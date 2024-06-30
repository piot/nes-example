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
    ; what remains in A should only be the 4 bit integer part
    lsr a                 ; Shift A right 1 bit
    lsr a                 ; Shift A right 1 bit
    lsr a                 ; Shift A right 1 bit
    lsr a                 ; Shift A right 1 bit

    sta temp

    tya

    ; make space for the other lower integer part
    asl a
    asl a
    asl a
    asl a
    ora temp

.endmacro
