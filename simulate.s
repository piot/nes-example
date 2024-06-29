simulate:
	jsr read_joypad_and_set_direction
	stx entity_input_directions ; the player avatar is on entity zero

	jsr update_x_acceleration_from_direction
    jsr update_x_speed_and_positions
	rts

; ------
update_x_acceleration_from_direction:
	ldx #0
	ldy #0
@loop:
	lda entity_input_directions,x
	asl a
	asl a
	asl a
	sta entity_accels,y
	bpl @positive_number
	lda #$ff
	jmp @set_integer_part
 @positive_number:
	lda #0
 @set_integer_part:
	sta entity_accels+1,y
	inx
	iny
	iny
	cpx #INPUT_DIRECTION_ARRAY_SIZE
	bne @loop
	rts

; ------
update_x_speed_and_positions:
	ldx #0
@loop:
    clc

	; speeds += accels
	; add fraction fixed point
	lda entity_speeds,x
    adc entity_accels,x
    sta entity_speeds,x

	; add integer fixed point
    lda entity_speeds+1,x
    adc entity_accels+1,x
    sta entity_speeds+1,x

    clc
	; positions += speeds
	; add fraction fixed point
    lda entity_positions,x
    adc entity_speeds,x
    sta entity_positions,x

	; add integer fixed point
    lda entity_positions+1,x
    adc entity_speeds+1,x
    sta entity_positions+1,x

	; Advance two octets (8.8 fixed point). speeds, accels and positions all have two octets
    inx
    inx

	cpx #COMMON_ARRAY_SIZE  ; Check if we've processed all entities, assume positions, speeds, accels
    bne @loop
	rts

