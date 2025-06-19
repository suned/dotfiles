{
  description = "suned's global nix packages";

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
          pkgs.nixd
          pkgs.nil
          pkgs.just
        ];
      };
    };
}
