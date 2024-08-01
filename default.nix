with import <nixpkgs> { };

stdenv.mkDerivation {
  name = "mt.olympOS";
  src = ./src;
  buildInputs = [ nasm file ];

  buildPhase = "nasm -f bin btl1.asm -o mt.olympOS.img";

  installPhase = ''
    mkdir -p $out/bin
    cp mt.olympOS.img $out/bin
  '';
}
