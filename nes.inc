;---------------------------------------------------------------------------------------------------
;  Copyright (c) Peter Bjorklund. All rights reserved. https://github.com/piot/nes-example
;  Licensed under the MIT License. See LICENSE in the project root for license information.
;---------------------------------------------------------------------------------------------------

; PPU. https://www.nesdev.org/wiki/PPU
; The "GPU" (Picture Processing Unit)

PPU_CTRL = $2000 ; https://www.nesdev.org/wiki/PPU_registers#PPUCTRL
PPU_MASK = $2001 ; https://www.nesdev.org/wiki/PPU_registers#PPUMASK
PPU_STATUS = $2002 ; https://www.nesdev.org/wiki/PPU_registers#PPUSTATUS
PPU_OAM_ADDR = $2003 ; https://www.nesdev.org/wiki/PPU_registers#OAMADDR
PPU_OAM_DATA = $2004 ; https://www.nesdev.org/wiki/PPU_registers#OAMDATA
PPU_SCROLL = $2005 ; https://www.nesdev.org/wiki/PPU_registers#PPUSCROLL
PPU_ADDR = $2006 ; https://www.nesdev.org/wiki/PPU_registers#PPUADDR
PPU_DATA = $2007 ; https://www.nesdev.org/wiki/PPU_registers#PPUDATA

; APU - Audio chip (audio processing unit) (https://www.nesdev.org/wiki/APU)

APU_PULSE1CTRL = $4000
APU_PULSE1RAMP = $4001
APU_PULSE1FTUNE = $4002
APU_PULSE1CTUNE = $4003
APU_PULSE2CTRL = $4004
APU_PULSE2RAMP = $4005
APU_PULSE2FTUNE = $4006
APU_PULSE2STUNE = $4007
APU_TRICTRL1 = $4008
APU_TRICTRL2 = $4009
APU_TRIFREQ1 = $400A
APU_TRIFREQ2 = $400B
APU_NOISECTRL = $400C
; $400D Unused?
APU_NOISEFREQ1 = $400E
APU_NOISEFREQ2 = $400F
APU_MODCTRL = $4010
APU_MODDA = $4011
APU_MODADDR = $4012
APU_MODLEN = $4013
OAM_DMA = $4014 ; https://www.nesdev.org/wiki/PPU_registers#OAMDMA
SND_CHN = $4015

APU_JOYPAD1 = $4016 ; https://www.nesdev.org/wiki/Standard_controller
APU_JOYPAD2 = $4017 ; https://www.nesdev.org/wiki/Standard_controller
