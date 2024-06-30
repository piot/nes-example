;---------------------------------------------------------------------------------------------------
;  Copyright (c) Peter Bjorklund. All rights reserved. https://github.com/piot/nes-example
;  Licensed under the MIT License. See LICENSE in the project root for license information.
;---------------------------------------------------------------------------------------------------

; PPU functions

initialize_ppu:
	lda #%00001000
	sta PPU_CTRL
	lda #%00011110     ; Enable background rendering
	sta PPU_MASK
	rts

; busy wait for the vertical blanking to start
wait_vertical_blank:
	bit PPU_STATUS
	bpl wait_vertical_blank
	rts

; Change the common background color (first entry in the palette)
change_background_color:
	pha
	lda #$3F
	sta PPU_ADDR ; Set PPU address high byte
	lda #$00
	sta PPU_ADDR ; Set PPU address low byte
	pla ; Load the background color value
	sta PPU_DATA ; Write color to PPU
	rts

; Initialize the palettes
; https://www.nesdev.org/wiki/PPU_palettes
; (4 colors for each palette. 4 palettes for background AND 4 for sprites = 8 x 4)
; first color in first palette is normally used as the default universal background color
initialize_palettes:
	lda #$3F ; Palette starts at $3F00
	sta PPU_ADDR ; Set PPU address high byte
	lda #$00
	sta PPU_ADDR ; Set PPU address low byte

    ldx #0
@loop:
    lda palette_colors, x   ; Load color value from palette_colors array
    sta PPU_DATA      ; Write to PPU data port (palette memory)
    inx             ; Increment X to move to next palette entry
    cpx #32          ; Check if we've written all 32 entries
    bne @loop

    rts

hide_sprites:
   lda #255
   ldx #0

@next_sprite:
   sta oam, x ; set sprite Y = 255. Sprites are always enabled, but put them outside of the lower part of the screen.
   inx ; move past y position
   inx ; skip tile_number
   inx ; skip attributes
   inx ; skip X position
   bne @next_sprite ; sprite data is 256 octets, so when X is 0 again, we are done
   rts

; set the basic information for a sprite. normally the sprite attributes are not set in runtime
; for most sprites (e.g. changing palette or priority)
; a = sprite number, x=x, y=y
set_sprite:
	txa
	pha ; save x

	lda sprite_number
	asl
	asl ; sprite number x 4
	tax

	tya
	sta oam, x ; store Y
	inx

	lda tile_num
	sta oam, x ; store tile_num
	inx

	inx ; skip attributes

	pla ; pop x
	sta oam, x
	rts

; defines the sprite the first time, usually the sprite attribute doesn't have to
; be updated each tick
define_sprite:
	txa
	pha ; save x

	lda sprite_number
	asl
	asl ; sprite number x 4
	tax

	tya
	sta oam, x ; store Y
	inx

	lda tile_num
	sta oam, x ; store tile_num
	inx

	lda sprite_attribute
	sta oam, x
	inx

	pla ; pop X
	sta oam, x
	rts

; copy all sprite data from RAM ($0200) to PPU
dma_all_sprites:
	lda #$02 ; dma copy from $0200 to OAM
	sta OAM_DMA
	rts
