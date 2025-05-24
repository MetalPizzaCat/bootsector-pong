main:
	nasm -f bin -o game.bin main.asm

clean:
	rm -f game.bin
	rm -f game.com