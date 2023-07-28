# Cube
This project consists in a literal cube spinning around.<br>
Everything of it was made in pure x86 nasm.<br>
Using [graphics mode 13h](http://www.columbia.edu/~em36/wpdos/videomodes.txt) (320x200).<br>
And it fits into a boot sector.

### WARNING:
It may not work on real hardware, if your particular bios decides to overwrite the [BPB](https://en.wikipedia.org/wiki/BIOS_parameter_block), which in this case coincides with the actual code, thus making it unusable.