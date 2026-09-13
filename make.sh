cd "Bootloader 1&2"
echo assembling the bootloader
nasm -f bin bootloaderStage1.asm -o boot.bin
nasm -f bin bootloaderStage2.asm -o boot2.bin
echo assembled the bootloader files, now moving them to the imaging part
mv *.bin ../../
echo moved the files, moving onto the kernel modules and kernel
cd ..
cd "kernel modules"
nasm -f bin irqtimer.asm -o timer.bin
nasm -f bin Lib.asm -o library.bin
nasm -f bin command_int.asm -o cmd_int.bin
cd "mmu"
nasm -f bin mem_interface.asm -o memIO.bin
nasm -f bin memory_map_create.asm -o mem.bin
nasm -f bin PFA.asm -o Phys.bin
nasm -f bin paging.asm -o page.bin
nasm -f bin heap.asm -o heap.bin
mv *.bin ../../../
cd ..
cd "drivers"
cd "HDD"
nasm -f bin ATA.asm -o ataHW.bin
mv *.bin ../../../../
cd ..
cd "keyboard"
nasm -f bin hardware.asm -o keyHW.bin
mv *.bin ../../../../
cd ..
cd ..
mv *.bin ../../
cd ..
echo kernel modules done and moved
cd kernel
nasm -f bin Actualkernel.asm -o Pstage2.bin
mv *.bin ../../