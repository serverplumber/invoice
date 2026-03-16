{ inputs, projectName, ... }:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem = { pkgs, config, ... }:
  let
    krump = import ./krump.nix { inherit pkgs projectName; };
    containerDirs = builtins.attrNames (
      pkgs.lib.filterAttrs
       (name: type: type == "directory")
       (builtins.readDir ../containers)
    );
  in
  {
    apps = builtins.listToAttrs (map (name: {
      name = "${name}-image";
      value = krump.streamContainer name;
    }) containerDirs);
  };
}
