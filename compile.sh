ca65 main.s -g -o main.o --cpu 6502
ld65 -C nes.cfg -o game.nes main.o
