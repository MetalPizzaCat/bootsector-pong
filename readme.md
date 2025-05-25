# Bootsector pong
This is a simple build of pong that can fit entirely in the x86 first page boot sector. 
This is essentially a bootloader that instead of loading anything, runs pong. This was partially written as a challenge for myself, but also because i found it funny to use x86 PC this way.
This was written in x86 assembly and uses nasm as assembler. 

![image](https://github.com/user-attachments/assets/bec93c0b-6c16-4671-bee0-218e6ae11d3a)

# Features

The entire code fits within 512 bytes and uses only 507 bytes. This could be reduced significantly, however i wanted paddles to be thicker than one line which significantly complicated graphics and collision code
* Ability to play pong against computer
* Score
* Game over screen


# Running 
This needs to be assembled to be run, which can be done using provided makefile by running `make` in the root folder of the project.
```sh
git clone https://github.com/MetalPizzaCat/bootsector-pong.git
cd bootsector-pong
make
```
This can then be used with [qemu](https://www.qemu.org/) or anything similar to be run. 
Full example(excluding installation of tools) would be:
```sh
git clone https://github.com/MetalPizzaCat/bootsector-pong.git
cd bootsector-pong
make
qemu-system-i386 -fda game.bin
```

## Dump of the game
```
00000000  b8 13 00 cd 10 b8 00 a0  8e c0 bf 00 fa 26 c6 05  |.............&..|
00000010  00 4f 75 f9 a1 ec 7d 8b  1e ee 7d b2 0f b9 04 04  |.Ou...}...}.....|
00000020  e8 96 01 b8 14 00 8b 1e  f5 7d b2 0e b9 04 28 e8  |.........}....(.|
00000030  87 01 b8 2c 01 8b 1e f8  7d b2 0d b9 04 28 e8 78  |...,....}....(.x|
00000040  01 ba 01 03 a0 f7 7d 04  30 b3 0e e8 58 01 ba 26  |......}.0...X..&|
00000050  03 a0 fa 7d 04 30 b3 0d  e8 4b 01 a0 eb 7d 84 c0  |...}.0...K...}..|
00000060  74 23 bf e1 7d b9 0a 00  b2 0f b6 0c b3 0c 8a 05  |t#..}...........|
00000070  51 e8 32 01 59 fe c2 47  e2 f4 e4 60 3c 39 0f 84  |Q.2.Y..G...`<9..|
00000080  13 01 e9 c8 00 e4 60 3c  39 75 07 c6 06 f4 7d 01  |......`<9u....}.|
00000090  eb 26 3c 11 74 06 3c 1f  74 0f eb 1c a1 f5 7d 85  |.&<.t.<.t.....}.|
000000a0  c0 74 15 ff 0e f5 7d eb  0f a1 f5 7d 83 c0 28 3d  |.t....}....}..(=|
000000b0  c8 00 74 04 ff 06 f5 7d  8b 0e ec 7d 81 f9 b4 00  |..t....}...}....|
000000c0  7e 1f 8b 0e f8 7d 3b 0e  ee 7d 7f 0b 83 c1 28 3b  |~....};..}....(;|
000000d0  0e ee 7d 7c 08 eb 0a ff  0e f8 7d eb 04 ff 06 f8  |..}|......}.....|
000000e0  7d a0 f4 7d 84 c0 74 65  a1 ec 7d 03 06 f2 7d 74  |}..}..te..}...}t|
000000f0  71 3d 40 01 74 66 89 c2  83 e8 04 83 f8 14 75 13  |q=@.tf........u.|
00000100  8b 0e f5 7d 3b 0e ee 7d  7f 09 83 c1 28 3b 0e ee  |...};..}....(;..|
00000110  7d 7d 1d 89 d0 83 c0 04  3d 2c 01 75 17 8b 0e f8  |}}......=,.u....|
00000120  7d 3b 0e ee 7d 7f 0d 83  c1 28 3b 0e ee 7d 7c 04  |};..}....(;..}|.|
00000130  f7 1e f2 7d 89 16 ec 7d  a1 ee 7d 03 06 f0 7d 74  |...}...}..}...}t|
00000140  05 3d c8 00 75 04 f7 1e  f0 7d a3 ee 7d b4 86 b9  |.=..u....}..}...|
00000150  00 00 ba 00 20 cd 15 e9  b0 fe eb fe fe 06 f7 7d  |.... ..........}|
00000160  eb 04 fe 06 fa 7d 80 3e  f7 7d 09 75 05 c6 06 eb  |.....}.>.}.u....|
00000170  7d 01 80 3e fa 7d 09 75  05 c6 06 eb 7d 01 c6 06  |}..>.}.u....}...|
00000180  f4 7d 00 c7 06 ec 7d 9e  00 c7 06 ee 7d 62 00 f7  |.}....}.....}b..|
00000190  1e f2 7d eb b8 c6 06 f7  7d 00 c6 06 fa 7d 00 c6  |..}.....}....}..|
000001a0  06 eb 7d 00 eb d8 b7 00  50 53 b8 00 02 cd 10 5b  |..}.....PS.....[|
000001b0  58 b4 0a b9 01 00 cd 10  c3 89 0e df 7d 31 c9 8a  |X...........}1..|
000001c0  0e df 7d 53 51 8a 0e e0  7d 53 69 db 40 01 89 c7  |..}SQ...}Si.@...|
000001d0  01 df 26 88 15 5b 43 e2  f0 59 40 5b e2 e5 c3 00  |..&..[C..Y@[....|
000001e0  00 47 61 6d 65 20 6f 76  65 72 21 00 9e 00 62 00  |.Game over!...b.|
000001f0  01 00 01 00 00 50 00 00  50 00 00 4f 4f 4f 55 aa  |.....P..P..OOOU.
```

## Code notes
This project was inspired by https://github.com/zenoamaro/bootloader-pong
