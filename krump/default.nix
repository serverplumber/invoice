{ pkgs }:
{
  devTools = with pkgs; [
    bat
    curl
    eza
    git
    glow
    gnugrep
    gnused
    harper
    helix
    jq
    just
    lowdown
    mdformat
    neovim
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nix
    starship
    vim
    wget
  ];

  env = {
    NIXPKGS_ALLOW_UNFREE = "1";
    FONTCONFIG_PATH = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts";
  };

  shellHook = shell: ''
    alias ls='${pkgs.eza}/bin/eza --icons'
    alias tree='${pkgs.eza}/bin/eza --tree --icons'
    eval "$(${pkgs.starship}/bin/starship init ${shell})"
  '';
}
