.include "nes.inc"
; --------------------------------------------------------------------------------------------------
; The header is the information about the NES cartridge, that determines things as the
; ROM banks and if it is for NTSC or PAL and similar.
.segment "HEADER"
.byte "NES", $1A ; ID
.byte 2 ; Number of 16 KB PRG ROM banks
.byte 1 ; Number of 8 KB CHR ROM banks
.byte $01 ; Flags 6: Mapper, mirroring, battery, trainer
.byte $00 ; Flags 7: Mapper, VS/Playchoice, NES 2.0
.byte $00 ; Flags 8: PRG-RAM size
.byte $01 ; Flags 9: TV system - PAL
.byte $00 ; Flags 10: TV system, PRG-RAM presence
.byte $00, $00, $00, $00, $00 ; Padding bytes


; --------------------------------------------------------------------------------------------------
; The tile information in ROM. The colors that define each pixel. NES has two BIT planes, with a possibility
; of three colors (and a background color) for each pixel. Each spritet takes up 16 octets.
; The colors are looked up using the palette specified in the sprite attributes.
.segment "TILES"
.incbin "background.chr"
.incbin "sprites.chr"


; --------------------------------------------------------------------------------------------------
; ReadOnlyData. Constant values that never change.
.segment "RODATA"
palette_colors:
; https://www.nesdev.org/wiki/PPU_palettes#Palettes
;.byte $2d ; gray. universal background color
;.byte $2d ; red. for the hat. pal0, color1
;.byte $2d ; skinton-ish. pal0, color2
;.byte $2d ; eye and mouth. pal0, color3
.res 16 ; to be defined later
; Sprite palette
.byte $2d ; gray. universal background color
.byte $05 ; red. for the hat. pal4, color1
.byte $38 ; eye and mouth. pal4, color2
.byte $17 ; skinton-ish. pal4, color3
.res 12 ; to be defined later

; --------------------------------------------------------------------------------------------------
; Zero page segment must be before code segments, so the compiler knows
; that it should use zero-page-addressing.
; Here are all the variables needed for the game. It is recommended to keep it to under 256 octets
; for faster access. Only add variables that change, add constant things to RODATA segment.
.segment "ZEROPAGE"
bg_color: .res 1
tile_num: .res 1
sprite_number: .res 1
sprite_attribute: .res 1

; --------------------------------------------------------------------------------------------------
; Here are the boot pointers so the NES knows what address to call for nmi, irq AND reset.
; on boot up it calls the reset vector.
.segment "VECTORS"
.word nmi
.word reset
.word irq

; --------------------------------------------------------------------------------------------------
; We store the sprite (OAM) information in this RAM area. The data here will be copied using a very
; fast DMA transfer to the graphics chip (PPU) after each vertical blank.
.segment "OAM"
oam: .res 256 ; sprite OAM data to be uploaded by DMA

; --------------------------------------------------------------------------------------------------
; Here follows the normal code
.segment "CODE"
reset:
	sei ; Disable interrupts. Should be first to make sure no interupt happens
	lda #0 ;
	sta PPU_CTRL ; disable NMI. again, do it early to avoid interrupt.
	sta PPU_MASK ; disable rendering
	sta SND_CHN ; disable APU sound
	sta APU_MODCTRL ; disable DMC IRQ

	cld ; Clear decimal mode

	ldx #$FF    ; Initialize stack pointer to $FF
	txs ; initialize stack

@clear_ram:
; clear all 2KB of RAM to 0, not that this will overwrite the stack, so it can not be in a subroutine.
	lda #$00       ; load 0 into a register
	ldx #$00       ; load 0 into x register

@clear_loop:
	sta $0000, x
	sta $0100, x
	sta $0200, x
	sta $0300, x
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $0700, x
	inx
	bne @clear_loop ; loops 256 times

	jsr wait_vertical_blank
	jsr initialize_ppu
	jsr initialize_palettes
	jsr hide_sprites

	lda #$2D ; gray color
	jsr change_background_color

	jsr wait_vertical_blank
	jsr init

	jmp main_loop

initialize_ppu:
	lda #%00001000
	sta PPU_CTRL
	lda #%00011110     ; Enable background rendering
	sta PPU_MASK
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

wait_vertical_blank:
	bit PPU_STATUS
	bpl wait_vertical_blank
	rts

main_loop:
	jsr wait_vertical_blank
	jsr tick
	jmp main_loop


change_background_color:
	pha
	lda #$3F
	sta PPU_ADDR ; Set PPU address high byte
	lda #$00
	sta PPU_ADDR ; Set PPU address low byte
	pla ; Load the background color value
	sta PPU_DATA ; Write color to PPU
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

	;lda #0 ; store attributes
	;sta oam, x
	inx

	pla ; pop x
	sta oam, x
	rts

; defines the sprite the first time, usually the sprite attribute doesnt have to
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

dma_all_sprites:
	lda #$02 ; dma copy from $0200 to OAM
	sta OAM_DMA
	rts

init:
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

tick:
	inc bg_color

	lda #0
	sta sprite_number
	ldx bg_color
	ldy #0
	lda #0
	sta tile_num
	jsr set_sprite

	lda #1
	sta sprite_number

	; offset X with 8
	lda bg_color
	clc ; clear carry, otherwise it might be added in the adc opcode
	adc #8
	tax

	ldy #0
	lda #1
	sta tile_num
	jsr set_sprite


	lda #2
	sta sprite_number

	ldx bg_color
	ldy #8
	lda #16
	sta tile_num
	jsr set_sprite


	lda #3
	sta sprite_number

	; offset X with 8
	lda bg_color
	clc ; clear carry, otherwise it might be added in the adc opcode
	adc #8
	tax
	ldy #8
	lda #17
	sta tile_num
	jsr set_sprite

	jsr dma_all_sprites

	rts

nmi:
	; ignore NMI
	rti

irq:
	; ignore IRQ
	rti
