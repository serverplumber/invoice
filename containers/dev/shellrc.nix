{ pkgs, krump }:
{
  bash = pkgs.writeTextFile {
    name = "bashrc";
    destination = "/etc/bashrc";
    text = krump.shellHook "bash";
  };

  zsh = pkgs.writeTextFile {
    name = "zshrc";
    destination = "/etc/zshrc";
    text = krump.shellHook "zsh";
  };

  fish = pkgs.writeTextFile {
    name = "fish-config";
    destination = "/etc/fish/config.fish";
    text = krump.shellHook "fish";
  };
}
