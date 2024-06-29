; reads the first joypad
; https://www.nesdev.org/wiki/Controller_reading
; https://www.nesdev.org/wiki/Controller_reading_code
; returns bitmask in X
; each octet read is only returned as $00 (pressed) or $01 (not pressed)
; |A|B|Select|Start|Up|Down|Left|Right
read_joypad0:
    lda #$01 ; Signal that the controller should be read now
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    sta APU_JOYPAD1

    lda #0 ; Signal that the poll is over
    ; By storing 0 into APU_JOYPAD1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from APU_JOYPAD1.
    sta APU_JOYPAD1

    ldy #8
    ldx #0

@loop:
    lda APU_JOYPAD1
    lsr a        ; shift right. this is only done to get bit 0 -> Carry

    txa
    rol a ; rotate left, bit 0 is set from carry
    tax

    dey
    bne @loop

    rts
