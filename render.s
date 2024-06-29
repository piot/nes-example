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
	lda #0
	sta sprite_number
	ldx entity_positions+1
	ldy #0
	lda #0
	sta tile_num
	jsr set_sprite

	lda #1
	sta sprite_number

	; offset X with 8
	lda entity_positions+1
	clc ; clear carry, otherwise it might be added in the adc opcode
	adc #8
	tax

	ldy #0
	lda #1
	sta tile_num
	jsr set_sprite


	lda #2
	sta sprite_number

	ldx entity_positions+1
	ldy #8
	lda #16
	sta tile_num
	jsr set_sprite


	lda #3
	sta sprite_number

	; offset X with 8
	lda entity_positions+1
	clc ; clear carry, otherwise it might be added in the adc opcode
	adc #8
	tax
	ldy #8
	lda #17
	sta tile_num
	jsr set_sprite

	jsr dma_all_sprites

	rts
