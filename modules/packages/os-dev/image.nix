{
  stdenv,
  lib,
  fetchFromGitea,
  qemu_test,
  pkgs,
}:
stdenv.mkDerivation rec {
  pname = "mt_olympOS";
  version = "";

  src = fetchFromGitea {
    domain = "git.nix2twink.gay";
    owner = "lucy";
    repo = "mt.olympOS";
    rev = "4f50cc97e2cbe70b9c58f9f521f4b8fd839a5af3";
    sha256 = "lMDxvKmX7SA8oQapXwKtx+Kf7ucWi/Mpxn16YDBmpoI=";
  };

  buildInputs = [
    qemu_test
    pkgs.nasm
    pkgs.file
  ];

  buildPhase = ''
    nasm -f bin src/btl1.asm -o boot1.bin
    nasm -f bin src/btl2.asm -o boot2.bin
    qemu-img create -f raw mt.olympOS.img 1M
    dd if=boot1.bin of=mt.olympOS.img bs=512M count=1 conv=notrunc
    dd if=boot2.bin of=mt.olympOS.img bs=512 seek=1 conv=notrunc
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp mt.olympOS.img $out/bin
  '';

  meta = with lib; {
    description = "mt OlympOS";
    homepage = "https://git.nix2twink.gay/lucy/${pname}";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}

