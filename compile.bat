@echo off
nasm "cube.asm" -f bin -o "bin/cube.bin"
cd bin
copy /b cube.bin cube.img
cd ..