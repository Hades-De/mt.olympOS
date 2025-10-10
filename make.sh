cd "Bootloader 1&2"
echo assembling the bootloader
nasm -f bin bootloaderStage1.asm -o boot.bin
nasm -f bin bootloaderStage2.asm -o boot2.bin
echo assembled the bootloader files, now moving them to the imaging part
mv *.bin ../../
echo moved the files, moving onto the kernel modules and kernel
cd ..
cd "kernel modules"
nasm -f bin command_parsing.asm -o parser.bin
nasm -f bin irqtimer.asm -o timer.bin
nasm -f bin KEYBOARD_driver.asm -o keyboard.bin
nasm -f bin MemHandler_assigner.asm -o memhandler.bin
nasm -f bin memory_map_create.asm -o mem.bin
nasm -f bin VGA_driver.asm -o VGA.bin
mv *.bin ../../
cd ..
echo kernel modules done and moved
cd kernel
nasm -f bin Actualkernel.asm -o Pstage2.bin
mv *.bin ../../