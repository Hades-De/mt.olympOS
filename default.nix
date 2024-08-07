with import <nixpkgs> { };

stdenv.mkDerivation {
  name = "mt.olympOS";
  src = ./src;
  buildInputs = [ qemu_test nasm file ];

  buildPhase = "nasm -f bin blt1.asm -o blt1.bin && nasm -f bin blt2.asm -o blt2.bin && qemu-img create -f raw mt.olympOS.img 1M && dd if=boot1.bin of=mt.olympOS.img bs=512M count=1 conv=notrunc && dd if=boot2.bin of=mt.olympOS.img bs=512 seek=1 conv=notrunc";

  installPhase = ''
    mkdir -p $out/bin
    cp disk.img $out/bin
  '';
}
