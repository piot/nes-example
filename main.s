;---------------------------------------------------------------------------------------------------
;  Copyright (c) Peter Bjorklund. All rights reserved. https://github.com/piot/nes-example
;  Licensed under the MIT License. See LICENSE in the project root for license information.
;---------------------------------------------------------------------------------------------------

; --------------------------------------------------------------------------------------------------
; The header is the information about the NES cartridge, that determines things as the
; ROM banks and if it is for NTSC or PAL and similar.
; https://www.nesdev.org/wiki/INES
.segment "HEADER"
.byte "NES", $1A ; ID
.byte 2 ; Number of 16 KB PRG ROM banks
.byte 1 ; Number of 8 KB CHR ROM banks
.byte $00 ; Flags 6: Mapper, mirroring, battery, trainer
.byte $00 ; Flags 7: Mapper, VS/Playchoice, NES 2.0, 0 = original NES
.byte $00 ; Flags 8: PRG-RAM size
.byte $01 ; Flags 9: TV-system, 01 = PAL
.byte $00 ; Flags 10: TV system, PRG-RAM presence (unofficial, rarely used extension)
.byte $00, $00, $00, $00, $00  ; reserved

; --------------------------------------------------------------------------------------------------
; Zero page segment must be before code segments, so the compiler knows
; that it should use zero-page-addressing.
; Here are all the variables needed for the game. It is recommended to keep it to under 256 octets
; for faster access. Only add variables that change, add constant things to RODATA segment.
.segment "ZEROPAGE"
temp: .res 1
bg_color: .res 1
tile_num: .res 1
sprite_number: .res 1
sprite_attribute: .res 1
position_x_integer: .res 1
position_y_integer: .res 1
facing_x: .res 1
offset_x_left: .res 1
offset_x_right: .res 1

fixed_value1: .res 2
fixed_value2: .res 2

; --------------------------------------------------------------------------------------------------
; BSS segment
.segment "BSS" ; RAM variables that doesn't fit in ZEROPAGE
NUM_ENTITIES = $10
ENTITY_POS_SIZE = 2        ; Each position is 2 octets (12.4 fixed-point)
ENTITY_VELOCITY_SIZE = 1      ; Each velocity is 1 octet (4.4 fixed-point)
ENTITY_INPUT_DIRECTION_SIZE = 1 ; $00, $01 or $FF

POS_ARRAY_SIZE = ENTITY_POS_SIZE * NUM_ENTITIES
VELOCITY_ARRAY_SIZE = ENTITY_VELOCITY_SIZE * NUM_ENTITIES
MAX_VELOCITY_ARRAY_SIZE = VELOCITY_ARRAY_SIZE
COMMON_ARRAY_SIZE = POS_ARRAY_SIZE
INPUT_DIRECTION_ARRAY_SIZE = ENTITY_INPUT_DIRECTION_SIZE * NUM_ENTITIES

; x-values

entity_x_positions:
    .res POS_ARRAY_SIZE

entity_x_velocities:
    .res VELOCITY_ARRAY_SIZE

entity_target_x_velocities:
    .res VELOCITY_ARRAY_SIZE

entity_facings:
	.res VELOCITY_ARRAY_SIZE

entity_input_x_directions:
    .res INPUT_DIRECTION_ARRAY_SIZE

; y-values

entity_input_action:
    .res VELOCITY_ARRAY_SIZE

entity_y_positions:
    .res POS_ARRAY_SIZE

entity_y_velocities:
    .res VELOCITY_ARRAY_SIZE

entity_y_gravities:
    .res VELOCITY_ARRAY_SIZE


entity_status:
    .res VELOCITY_ARRAY_SIZE


; --------------------------------------------------------------------------------------------------
; We store the sprite (OAM) information in this RAM area. The data here will be copied using a very
; fast DMA transfer to the graphics chip (PPU) after each vertical blank.
.segment "OAM"
oam: .res 256 ; sprite OAM data to be uploaded by DMA

; --------------------------------------------------------------------------------------------------
; The tile information in ROM. The colors that define each pixel. NES has two BIT planes, with a possibility
; of three colors (and a background color) for each pixel. Each spritet takes up 16 octets.
; The colors are looked up using the palette specified in the sprite attributes.
.segment "TILES"
.incbin "background.chr"
.incbin "sprites.chr"

; --------------------------------------------------------------------------------------------------
; Here are the boot pointers so the NES knows what address to call for nmi, irq AND reset.
; on boot up it calls the reset vector.
.segment "VECTORS"
.word nmi
.word reset
.word irq

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


; shared includes first
.include "nes.inc"
.include "fixedpoint.s"

; sub systems
.include "input.s"
.include "ppu.s"
.include "render.s"
.include "simulate.s"

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

	cld ; Clear decimal mode. It is never used in a normal game.

	ldx #$FF    ; Initialize stack pointer to $FF
	txs ; initialize stack

; clearing is not really neccessary, but makes debugging so much easier since you can see a pattern
; where data actually is stored.
@clear_ram:
; clear all 2KB of RAM to 0, not that this will overwrite the stack, so it can not be in a subroutine.
	lda #$00       ; load 0 into a register
	ldx #$00       ; load 0 into x register

@clear_loop:
	sta $0000,x
	sta $0100,x
	sta $0200,x
	sta $0300,x
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	inx
	bne @clear_loop ; loops 256 times

	jsr wait_vertical_blank ; can only write to the PPU when in vertical blank (not rendering)
	jsr render_init
	jsr simulate_init

	jmp main_loop


main_loop:
	jsr wait_vertical_blank
	jsr render
	jsr simulate
	jmp main_loop

;
read_joypad_and_set_direction:
	jsr read_joypad0
	txa ; put read mask in a
	tay ; for later processing below
	ldx #0
	and #$01 ; test right
	beq @check_left ; if zero jump
	ldx #1
	jmp @check_vertical
@check_left:
	tya ; bring back the mask from y
	and #$02 ; test left
	beq @check_vertical ; if zero jump
	ldx #$ff ; -1
@check_vertical:
	tya
	rts


nmi:
	; ignore NMI
	rti

irq:
	; ignore IRQ
	rti
