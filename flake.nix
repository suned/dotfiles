{
  description = "nix dev shell for my dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages."aarch64-darwin";
    in
    {
      devShells.aarch64-darwin.default = pkgs.mkShell {
        name = "nix-global-dev";
        packages = [
          pkgs.just
          pkgs.stow
        ];
      };
    };
}
