{ pkgs, projectName }:

let
  krump = import ../../krump { inherit pkgs; };
  containerDefaults = import ../../containers { inherit pkgs; };
  shellRc = import ./shellrc.nix { inherit pkgs krump; };
  # Setup script to create developer user if needed (optional for local dev)
  setupScript = pkgs.writeShellScriptBin "setup-dev-user" ''
    if ! id -u developer > /dev/null 2>&1; then
      echo "developer:x:1000:1000::/workspace:/bin/sh" >> /etc/passwd
      echo "developer:x:1000:" >> /etc/group
      echo "developer:!:19000:0:99999:7:::" >> /etc/shadow
    fi
    if [ "$#" -gt 0 ]; then
      exec "$@"
    fi
    case $SHELL in
      */sh|*/bash) export SHELL=${pkgs.bash}/bin/bash ;;
      */zsh) export SHELL=${pkgs.zsh}/bin/zsh ;;
      */fish) export SHELL=${pkgs.fish}/bin/fish ;;
      *) echo "Unsupported shell: $SHELL, falling back to bash" && export SHELL=${pkgs.bash}/bin/bash ;;
    esac
    exec $SHELL
  '';
  users = containerDefaults.makeUsers [
    {
      name = "root";
      uid = 0;
      gid = 0;
      home = "/root";
      shell = "${pkgs.bash}/bin/bash";
    }
    {
      name = "vscode";
      uid = 1000;
      gid = 1000;
      home = "/home/vscode";
      shell = "${pkgs.bash}/bin/bash";
    }
  ];
  osRelease = pkgs.writeTextFile {
    name = "os-release";
    destination = "/etc/os-release";
    text = ''
      ID=nixos
      NAME="NixOS"
      PRETTY_NAME="NixOS (krump)"
    '';
  };

in
{
  # The dev container: everything needed for interactive development
  image = pkgs.dockerTools.streamLayeredImage {
    name = "${projectName}-dev";
    tag = "latest";

    contents = pkgs.buildEnv {
      name = "dev-root";
      paths =
        krump.devTools
        ++ [
          setupScript
          containerDefaults.nixConf
          containerDefaults.tmpDir
          shellRc.bash
          shellRc.zsh
          shellRc.fish
          users.passwd
          users.group
          users.shadow
          osRelease
        ]
        ++ (with pkgs; [
          bash
          coreutils
          cacert
          shadow
        ]);
    };

    fakeRootCommands = ''
      mkdir -p /root
      chmod 777 /root
      mkdir -p /home/vscode
      mkdir -p /workspace
      mkdir -p /usr/bin
      mkdir -p /lib64
      mkdir -p /lib/x86_64-linux-gnu
      mkdir -p /usr/lib/x86_64-linux-gnu
      cp ${pkgs.glibc}/lib/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
      cp ${pkgs.glibc}/lib/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
      cp ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6
      cp ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6 /usr/lib/libstdc++.so.6
      ln -s ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
      cp ${pkgs.gnugrep}/bin/grep /usr/bin/grep
      cp ${pkgs.gnused}/bin/sed /usr/bin/sed
      cp ${pkgs.coreutils}/bin/* /usr/bin/
      cp --remove-destination ${pkgs.bash}/bin/bash /bin/sh
      chown -R 1000:1000 /home/vscode
    '';
    enableFakechroot = true;

    config = {
      Entrypoint = [ "${setupScript}/bin/setup-dev-user" ];
      Cmd = [ ];
      Env = [
        "PATH=${pkgs.lib.makeBinPath krump.devTools}:${pkgs.coreutils}/bin:/bin:/usr/bin"
        "NIXPKGS_ALLOW_UNFREE=1"
        "FONTCONFIG_PATH=${pkgs.nerd-fonts.jetbrains-mono}/share/fonts"
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu"
      ];
      WorkingDir = "/workspace";
    };
  };
}
