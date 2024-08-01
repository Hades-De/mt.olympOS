with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "mt.olympOS";
  src = ./.;

  buildInputs = [ nasm ];

  buildPhase = "nasm -f bin blt1.asm";

  installPhase = ''
    mkdir -p $out/bin
    cp main $out/bin/
  '';
}
