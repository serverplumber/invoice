# krump/shells.nix
{ inputs, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  perSystem = { pkgs, system, ... }:
  let
    krump = import ./default.nix { inherit pkgs; };

    bashShell = pkgs.mkShell {
      name = "dev-env-bash-${system}";
      buildInputs = krump.devTools ++ [ pkgs.bash ];
      inherit (krump.env) NIXPKGS_ALLOW_UNFREE FONTCONFIG_PATH;
      shellHook = krump.shellHook "bash";
    };

    zshShell = pkgs.mkShell {
      name = "dev-env-zsh-${system}";
      buildInputs = krump.devTools ++ [ pkgs.zsh ];
      inherit (krump.env) NIXPKGS_ALLOW_UNFREE FONTCONFIG_PATH;
      shellHook = krump.shellHook "zsh";
    };

    fishShell = pkgs.mkShell {
      name = "dev-env-fish-${system}";
      buildInputs = krump.devTools ++ [ pkgs.fish ];
      inherit (krump.env) NIXPKGS_ALLOW_UNFREE FONTCONFIG_PATH;
      shellHook = krump.shellHook "fish";
    };
  in
  {
    devShells = {
      default = bashShell;
      zsh     = zshShell;
      fish    = fishShell;
    };
  };
}
