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

	; since we can not add a signed 4.4 to an unsigned 12.4 fixed point, in a simple manner.
	; we unfortunately have to check the sign of the velocity and do custom code for each case.
	lda entity_velocities,x
	bmi @handle_negative

	; positive velocity case, it is super simple, the normal adc should work
	; positions += velocities
    lda entity_positions+1,x
    adc entity_velocities,y
    sta entity_positions+1,x

	lda #0
	adc entity_positions,x ; if carry is set ("overflow"), then position will be added by one otherwise zero
	sta entity_positions,x
	jmp @done

@handle_negative:
	; Negative velocity case
	; TODO: there must be a cleaner solution than this
	lda #0
	sec
	sbc entity_velocities,y ; convert negative velocity to a positive value that can be subtracted below
	sta temp ; store the positive velocity in temp
	lda entity_positions+1
	sec
	sbc temp ; subtract the positive velocity from the lower part of the position. the carry flag is set if it was negative.
	sta entity_positions+1 ; store the result back to the lower part

	lda entity_positions
	sbc #0 ; subtract the upper part of the position with 0 and carry. so if carry is set it subtracts 1, otherwise zero.
	sta entity_positions

@done:

	; Advance two octets (12.4 fixed point).
    inx
    inx
	iny

	cpx #POS_ARRAY_SIZE  ; Check if we've processed all entities
    bne @loop
	rts
