{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      path = "/home/mrtuxa/Documents/transtravel";
      pkgs = nixpkgs.legacyPackages.${system}.pkgs;
      presentationPath = "./presentation";
    in
    {
      packages.${system} = {
	default = pkgs.callPackage ./modules/packages/os-dev/image.nix {};
      };
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.nasm
	  pkgs.file
	  pkgs.nixfmt-rfc-style
	  pkgs.qemu_test
        ];
      };
    };
}

