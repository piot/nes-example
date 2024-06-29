del game.nes
ca65 main.s -g -o main.o -t nes
ld65 -C nes.cfg -o game.nes --dbgfile game.dbg main.o
