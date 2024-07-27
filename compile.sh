rm game.nes

set -x
ca65 -W 2 main.s -g -o main.o -t nes
ld65 -v -C nes.cfg -o game.nes --dbgfile game.dbg main.o
