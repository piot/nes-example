simulate_init:
	lda #$13
	sta entity_max_velocities ; set velocity for entity zero
	rts

simulate:
	jsr read_joypad_and_set_direction
	stx entity_input_directions ; the player avatar is on entity zero

	jsr set_x_velocity_from_direction
	jsr update_x_positions_from_velocity
	rts


; ------
set_x_velocity_from_direction:
	ldx #0
@loop:
	lda entity_input_directions,x
	asl a
	asl a
	asl a
	asl a
	sta entity_velocities,x
	inx
	cpx #INPUT_DIRECTION_ARRAY_SIZE
	bne @loop
	rts


update_x_positions_from_velocity:
	ldx #0
	ldy #0
@loop:
    clc

	; since we can not add a signed 4.4 to an unsigned 8.4 (12.4) fixed point, we
	; unfortunately have to check the sign of the velocity.
	lda entity_velocities,x
	bmi @handle_negative

	; positive case, it is super simple, the normal adc should work
	; positions += velocities
    lda entity_positions+1,x
    adc entity_velocities,y
    sta entity_positions+1,x

	lda #0
	adc entity_positions,x ; if carry is set ("overflow"), then position will be added by one otherwise zero
	sta entity_positions,x
	jmp @done

@handle_negative:
	; Negative velocity
	; TODO: there must be a cleaner solution than this
	lda #0
	sec
	sbc entity_velocities,y
	sta temp
	lda entity_positions+1
	sec
	sbc temp
	sta entity_positions+1
	lda entity_positions
	sbc #0
	sta entity_positions

@done:

	; Advance two octets (8.4 fixed point).
    inx
    inx
	iny

	cpx #POS_ARRAY_SIZE  ; Check if we've processed all entities
    bne @loop
	rts
