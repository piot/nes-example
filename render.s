;---------------------------------------------------------------------------------------------------
;  Copyright (c) Peter Bjorklund. All rights reserved. https://github.com/piot/nes-example
;  Licensed under the MIT License. See LICENSE in the project root for license information.
;---------------------------------------------------------------------------------------------------

render_init:
	jsr initialize_ppu
	jsr initialize_palettes
	jsr hide_sprites

	lda #$2D ; gray color
	jsr change_background_color

	lda #0
	sta sprite_number
	lda #0
	sta tile_num
	lda #0 ; use first palette entry
	sta sprite_attribute
	ldx bg_color
	ldy #0
	jsr define_sprite

	lda #1
	sta sprite_number
	lda #1
	sta tile_num
	lda #0 ; use first palette entry
	sta sprite_attribute
	ldx bg_color
	ldy #0
	jsr define_sprite
    rts

render:
	ldx #0

	ldy entity_x_positions,x
	lda entity_x_positions+1,x ; result in X
	FIXED_TO_INT ; Y=high octet, A = low octet, result in A
	sta position_x_integer ; store the resulting X position

	ldy entity_y_positions,x
	lda entity_y_positions+1,x ; result in X
	FIXED_TO_INT ; Y=high octet, A = low octet, result in A

	; lda #$10 ; TODO: Hack: position_y_integer is wrong at the moment, so show a constant y position.
	sta position_y_integer ; store the resulting y position


	ldy #0
	lda entity_facings,y
	sta facing_x
	cmp #0
	bmi @facing_left
	; facing right
	lda #0
	sta offset_x_right

	lda #8 ; negate this number
	eor #$FF   ; This inverts all bits in A
	clc        ; Clear the carry flag to ensure accurate addition
	adc #$01   ; Add 1 to the inverted byte
	sta offset_x_left
	jmp @facing_done

@facing_left:
	lda #8 ; negate this number
	eor #$FF   ; This inverts all bits in A
	clc        ; Clear the carry flag to ensure accurate addition
	adc #$01   ; Add 1 to the inverted byte
	sta offset_x_right
	lda #0
	sta offset_x_left
@facing_done:

	ldy #0

	lda #0
	sta sprite_number

	lda position_x_integer
	clc ; clear carry, otherwise it might be added in the adc opcode
	adc offset_x_left
	tax

	ldy position_y_integer
	lda #0
	sta tile_num
	jsr set_sprite

	lda #1
	sta sprite_number

	; offset X with 8
	lda position_x_integer
	clc ; clear carry, otherwise it might be added in the adc opcode
	adc offset_x_right
	tax

	ldy position_y_integer
	lda #1
	sta tile_num
	jsr set_sprite


	lda #2
	sta sprite_number

	lda position_x_integer
	clc ; clear carry, otherwise it might be added in the adc opcode
	adc offset_x_left
	tax

	lda position_y_integer
	clc
	adc #8
	tay ; position_y_integer+8

	lda #16
	sta tile_num
	jsr set_sprite


	lda #3
	sta sprite_number

	; offset X with 8
	lda position_x_integer
	clc ; clear carry, otherwise it might be added in the adc opcode
	adc offset_x_right
	tax

	lda position_y_integer
	clc
	adc #8
	tay ; position_y_integer+8

	lda #17
	sta tile_num
	jsr set_sprite

	jsr dma_all_sprites

	rts
