main:
	nasm -f bin -o game.bin main.asm


run: main
	qemu-system-i386 -fda game.bin

clean:
	rm -f game.bin
	rm -f game.com