{ pkgs }:
let
  tmpDir = pkgs.runCommand "tmp" { } ''
    mkdir -p $out/tmp
  '';
  nixConf = pkgs.writeTextFile {
    name = "nix.conf";
    destination = "/etc/nix/nix.conf";
    text = ''
      experimental-features = nix-command flakes
      sandbox = false
      build-users-group =
      ssl-cert-file = ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    '';
  };

  makePasswd =
    users:
    pkgs.writeTextFile {
      name = "passwd";
      destination = "/etc/passwd";
      text = builtins.concatStringsSep "\n" (
        map (
          u: "${u.name}:x:${toString u.uid}:${toString u.gid}:${u.gecos or u.name}:${u.home}:${u.shell}"
        ) users
      );
    };

  makeGroup =
    users:
    pkgs.writeTextFile {
      name = "group";
      destination = "/etc/group";
      text = builtins.concatStringsSep "\n" (map (u: "${u.name}:x:${toString u.gid}:") users);
    };

  makeShadow =
    users:
    pkgs.writeTextFile {
      name = "shadow";
      destination = "/etc/shadow";
      text = builtins.concatStringsSep "\n" (map (u: "${u.name}:!:19000:0:99999:7:::") users);
    };

  makeUsers = users: {
    passwd = makePasswd users;
    group = makeGroup users;
    shadow = makeShadow users;
  };

  vscodePkgs = [
    pkgs.stdenv.cc.cc.lib # libstdc++
    pkgs.glibc # libc + glibc
    pkgs.glibc.bin
  ];

in
{
  inherit
    makeUsers
    tmpDir
    nixConf
    vscodePkgs
    ;
}
