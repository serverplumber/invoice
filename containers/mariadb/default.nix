{ pkgs, projectName }:
let
initScript = pkgs.writeShellScriptBin "mariadb-entrypoint" ''
  if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db --datadir=/var/lib/mysql --user=root
  fi
  exec ${pkgs.mariadb}/bin/mariadbd \
    --datadir=/var/lib/mysql \
    --user=root \
    --console
'';
in
{
  image = pkgs.dockerTools.streamLayeredImage {
    name = "${projectName}-mariadb";
    tag = "latest";

    contents = pkgs.buildEnv {
      name = "mariadb-root";
      paths = [
        initScript
        pkgs.mariadb
        pkgs.fakeNss
        pkgs.busybox
      ];
    };

    config = {
      Entrypoint = [ "${initScript}/bin/mariadb-entrypoint" ];
      ExposedPorts = { "3306/tcp" = { }; };
    };
  };
}
