.include "nes.inc"
; --------------------------------------------------------------------------------------------------
.segment "HEADER"
.byte "NES", $1A ; ID
.byte 2 ; Number of 16 KB PRG ROM banks
.byte 0 ; Number of 8 KB CHR ROM banks
.byte $01 ; Flags 6: Mapper, mirroring, battery, trainer
.byte $00 ; Flags 7: Mapper, VS/Playchoice, NES 2.0
.byte $00 ; Flags 8: PRG-RAM size
.byte $01 ; Flags 9: TV system
.byte $00 ; Flags 10: TV system, PRG-RAM presence
.byte $00, $00, $00, $00, $00 ; Padding bytes


; --------------------------------------------------------------------------------------------------
.segment "RODATA"
tile_data:
	; Plane 0 (low bit)
	.byte %00111100 ; Row 0
	.byte %01100110 ; Row 1
	.byte %01100110 ; Row 2
	.byte %01100110 ; Row 3
	.byte %01111110 ; Row 4
	.byte %01111110 ; Row 5
	.byte %01100110 ; Row 6
	.byte %00000000 ; Row 7
	; Plane 1 (high bit)
	.byte %00000000 ; Row 0
	.byte %00000000 ; Row 1
	.byte %00011000 ; Row 2
	.byte %00100100 ; Row 3
	.byte %00111100 ; Row 4
	.byte %00100100 ; Row 5
	.byte %00011000 ; Row 6
	.byte %00000000 ; Row 7


; --------------------------------------------------------------------------------------------------
; Zero page segment must be before code segments, so the compiler knows
; that it should use zero-page-addressing.
.segment "ZEROPAGE"
bg_color: .res 1
tile_num: .res 1
sprite_number: .res 1
sprite_attribute: .res 1


; --------------------------------------------------------------------------------------------------
.segment "VECTORS"
; .org $FFFA
.word nmi
; .org $FFFC
.word reset
; .org $FFFE
.word irq

.segment "OAM"
oam: .res 256 ; sprite OAM data to be uploaded by DMA


; --------------------------------------------------------------------------------------------------
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

write_tile_data_to_vram:
	lda PPU_STATUS ; Read PPU status to reset the address latch
	lda #$10          ; Set PPU address to $2000 (start of nametable (pixel data) table)
	sta PPU_ADDR
	lda #$30
	sta PPU_ADDR

	ldx #$00          ; Initialize index to 0

@write_loop:
	lda tile_data, x ; Load tile data byte
	sta PPU_DATA ; Write to PPU
	inx ; Increment index
	cpx #$10          ; Check if all 16 bytes are written
	bne @write_loop ; Loop until all bytes are written

	rts ; Return from subroutine


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

dma_sprite:
	lda #$02 ; dma copy from $0200 to OAM
	sta OAM_DMA
	rts

init:
	jsr write_tile_data_to_vram

	lda #0
	sta sprite_number
	lda #3
	sta tile_num
	lda 1
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
	lda #3
	sta tile_num
	jsr set_sprite

	jsr dma_sprite

	rts

nmi:
	; ignore NMI
	rti

irq:
	; ignore IRQ
	rti
