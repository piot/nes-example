simulate_init:
	rts

simulate:
	jsr read_joypad_and_set_direction
	stx entity_input_x_directions ; the player avatar is on entity zero
	sta entity_input_action ; $80, $40 or $00


	jsr set_x_target_velocity_from_direction
	jsr change_x_velocity_towards_target_velocity
	jsr update_x_positions_from_velocity

	jsr set_gravity_from_input_action ; if pressing jump, gravity is changed
	jsr reset_velocity_from_input_action
	jsr check_start_jump ; if resting and action is jump, set a negative y velocity (up)
	jsr update_y_velocity_from_gravity
	jsr clamp_y_velocity
	jsr update_y_positions_from_velocity
	jsr clamp_y_positions_against_ground

	rts



clamp_y_positions_against_ground:
	ldx #0
	ldy #0
@loop:
	lda entity_y_positions,x
	sta fixed_value1
	lda entity_y_positions+1,x ; result in X
	sta fixed_value1+1

	lda #03
	sta fixed_value2
	lda #00
	sta fixed_value2+1

	FIXED_CMP fixed_value1, fixed_value2

	bpl @nothing_to_do
	bvc @nothing_to_do

	lda fixed_value2
	sta entity_y_positions,x
	lda fixed_value2+1
	sta entity_y_positions+1,x ; result in X

	lda #0
	;sta entity_y_velocities,y

	sta entity_status,y

@nothing_to_do:
	inx
	inx
	iny
	cpx #POS_ARRAY_SIZE
	bne @loop
	rts

; input_action => gravity
check_start_jump:
	ldx #0
@loop:
	lda entity_input_action,x
	and #$40
	beq @no_action ; no action skip status check

	lda entity_status,x
	cmp #0
	bne @no_action

	; is resting and wants to jump

	lda #$01
	sta entity_status,x


	lda #$ec ; (-80)
	sta entity_y_velocities,x

@no_action:
	inx
	cpx #VELOCITY_ARRAY_SIZE
	bne @loop
	rts


; input_action => gravity
reset_velocity_from_input_action:
	ldx #0
@loop:
	lda entity_input_action,x
	and #$40
	beq @reset_not_pressed
	lda #0
	sta entity_y_velocities,x
	sta entity_status,x
@reset_not_pressed:
	inx
	cpx #VELOCITY_ARRAY_SIZE
	bne @loop
	rts


; input_action => gravity
set_gravity_from_input_action:
	ldx #0
@loop:
	lda entity_input_action,x
	and #$80
	bne @jump_not_pressed

; action (jump) is pressed
	lda #$02
	jmp @done
@jump_not_pressed:
	lda #$06

@done:
	sta entity_y_gravities,x
	inx
	cpx #VELOCITY_ARRAY_SIZE
	bne @loop
	rts


; y_velocity += gravity
update_y_velocity_from_gravity:
	ldx #0
@loop:
	clc
	lda entity_y_velocities,x
	adc entity_y_gravities,x
	sta entity_y_velocities,x
	inx
	cpx #VELOCITY_ARRAY_SIZE
	bne @loop
	rts

MAX_VELOCITY=9

clamp_y_velocity:
	ldx #0
@loop:
	clc
	lda entity_y_velocities,x
	cmp #MAX_VELOCITY
	bmi @below
	lda #MAX_VELOCITY
	sta entity_y_velocities,x
@below:
	inx
	cpx #VELOCITY_ARRAY_SIZE
	bne @loop
	rts


; ------
set_x_target_velocity_from_direction:
	ldx #0
@loop:
	lda entity_input_x_directions,x
	cmp #0
	beq @equal
	bpl @positive
@negative:
	lda #$FF
	sta entity_facings,x
	lda #$e7
	jmp @done
@positive:
	lda #$01
	sta entity_facings,x
	lda #$19
	jmp @done
@equal:
	lda #0

@done:
	sta entity_target_x_velocities,x
	inx
	cpx #INPUT_DIRECTION_ARRAY_SIZE
	bne @loop
	rts

;
change_x_velocity_towards_target_velocity:
	ldx #0
@loop:
	lda entity_x_velocities,x
	sec
	sbc entity_target_x_velocities,x
	; if diff is zero we are done
	beq @done

	bmi @less_than
@greater_than:
	dec entity_x_velocities,x
	jmp @done
@less_than:
	inc entity_x_velocities,x
@done:
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
	lda entity_x_velocities,x
	bmi @handle_negative

	; positive velocity case, it is super simple, the normal adc should work
	; positions += velocities
    lda entity_x_positions+1,x
    adc entity_x_velocities,y
    sta entity_x_positions+1,x

	lda #0
	adc entity_x_positions,x ; if carry is set ("overflow"), then position will be added by one otherwise zero
	sta entity_x_positions,x
	jmp @done

@handle_negative:
	; Negative velocity case
	; TODO: there must be a cleaner solution than this
	lda #0
	sec
	sbc entity_x_velocities,y ; convert negative velocity to a positive value that can be subtracted below
	sta temp ; store the positive velocity in temp
	lda entity_x_positions+1
	sec
	sbc temp ; subtract the positive velocity from the lower part of the position. the carry flag is set if it was negative.
	sta entity_x_positions+1 ; store the result back to the lower part

	lda entity_x_positions
	sbc #0 ; subtract the upper part of the position with 0 and carry. so if carry is set it subtracts 1, otherwise zero.
	sta entity_x_positions

@done:

	; Advance two octets (12.4 fixed point).
    inx
    inx
	iny

	cpx #POS_ARRAY_SIZE  ; Check if we've processed all entities
    bne @loop
	rts






update_y_positions_from_velocity:
	ldx #0
	ldy #0
@loop:
    clc

	; since we can not add a signed 4.4 to an unsigned 12.4 fixed point, in a simple manner.
	; we unfortunately have to check the sign of the velocity and do custom code for each case.
	lda entity_y_velocities,x
	bmi @handle_negative

	; positive velocity case, it is super simple, the normal adc should work
	; positions += velocities
    lda entity_y_positions+1,x
    adc entity_y_velocities,y
    sta entity_y_positions+1,x

	lda #0
	adc entity_y_positions,x ; if carry is set ("overflow"), then position will be added by one otherwise zero
	sta entity_y_positions,x
	jmp @done

@handle_negative:
	; Negative velocity case
	; TODO: there must be a cleaner solution than this
	lda #0
	sec
	sbc entity_y_velocities,y ; convert negative velocity to a positive value that can be subtracted below
	sta temp ; store the positive velocity in temp
	lda entity_y_positions+1
	sec
	sbc temp ; subtract the positive velocity from the lower part of the position. the carry flag is set if it was negative.
	sta entity_y_positions+1 ; store the result back to the lower part

	lda entity_y_positions
	sbc #0 ; subtract the upper part of the position with 0 and carry. so if carry is set it subtracts 1, otherwise zero.
	sta entity_y_positions

@done:

	; Advance two octets (12.4 fixed point).
	inx
	inx
	iny

	cpx #POS_ARRAY_SIZE ; Check if we've processed all entities
	bne @loop
	rts
