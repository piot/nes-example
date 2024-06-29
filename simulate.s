simulate_init:
	lda #$70
	sta entity_max_speeds ; set for entity zero
	lda #$00
	sta entity_max_speeds+1
	rts

simulate:
	jsr read_joypad_and_set_direction
	stx entity_input_directions ; the player avatar is on entity zero

	jsr update_x_acceleration_from_direction
    jsr update_x_speed_from_acceleration
	jsr clamp_x_speed
	jsr update_x_positions_from_speed
	rts


clamp_x_speed:
	ldx #0
@loop:
	lda entity_speeds,x
	sta value_low
    lda entity_speeds+1,x
	sta value_high

	lda entity_max_speeds,x
	sta max_value_low
    lda entity_max_speeds+1,x
	sta max_value_high

	lda #$01
	sta min_value_low
	lda #$00
	sta min_value_high

	jsr clamp_fixed_point ; value_low and value_high is set

	lda value_low
	sta entity_speeds,x
	lda value_high
	sta entity_speeds+1,x

	inx ; increase by two since it is a fixed point
	inx

	cpx #SPEED_ARRAY_SIZE
	bne @loop
	rts

; ------
update_x_acceleration_from_direction:
	ldx #0
	ldy #0
@loop:
	lda entity_input_directions,x
	asl a
	sta entity_accels,y
	bpl @positive_number
	lda #$ff
	jmp @set_integer_part
 @positive_number:
	lda #0
 @set_integer_part:
	sta entity_accels+1,y

 	lda value_high

	inx
	iny
	iny
	cpx #INPUT_DIRECTION_ARRAY_SIZE
	bne @loop
	rts

; ------
update_x_speed_from_acceleration:
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

	; Advance two octets (8.8 fixed point). speeds, accels and positions all have two octets
    inx
    inx

	cpx #COMMON_ARRAY_SIZE  ; Check if we've processed all entities, assume positions, speeds, accels
    bne @loop
	rts

update_x_positions_from_speed:
	ldx #0
@loop:
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

