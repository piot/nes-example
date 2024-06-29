rm game.nes
ca65 main.s -g -o main.o -t nes # --cpu 6502
ld65 -C nes.cfg -o game.nes main.o
