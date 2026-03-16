{
  description = "Nix-based dev and container framework (nix-in-podman)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
    }:
    let
      projectName = "invoice";
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./krump/shells.nix
        ./krump/containers.nix
      ];
      _module.args = { inherit projectName; };
      flake.templates.default = {
        path = ./.;
        description = "krump: nix dev container & build pipeline";
      };
    };
}
