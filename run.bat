@echo off
@REM qemu-system-x86_64 -drive format=raw,file="bin/cube.bin",index=0,if=floppy -m 128M
qemu-system-x86_64 -drive format=raw,file="bin/cube.bin"
