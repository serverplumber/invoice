{ pkgs, projectName }:
let
  php = pkgs.frankenphp.php.buildEnv {
    extensions = ({ enabled, all }: enabled ++ (with all; [
      bcmath
      gmp
      curl
      zip
      intl
      iconv
      pdo_mysql
      tokenizer
      ctype
      opcache
    ]));
    extraConfig = ''
      memory_limit = 512M
      upload_max_filesize = 32M
      post_max_size = 32M
      max_execution_time = 120
    '';
  };

in {
  image = pkgs.dockerTools.streamLayeredImage {
    name = "invoiceninja";
    tag = "latest";

    contents = pkgs.buildEnv {
      name = "invoiceninja-root";
      paths = [
        php
        pkgs.fakeNss
        pkgs.busybox
      ];
    };

    config = {
      Cmd = [
        "${pkgs.frankenphp}/bin/frankenphp"
        "php-server"
        "--root" "/var/www/invoiceninja/public"
        "--listen" "0.0.0.0:8080"
      ];
      ExposedPorts = { "8080/tcp" = { }; };
      WorkingDir = "/var/www/invoiceninja";
      Env = [
        "APP_ENV=production"
        "APP_DEBUG=false"
        "LOG_CHANNEL=stderr"
        "SESSION_DRIVER=database"
        "QUEUE_CONNECTION=database"
      ];
    };
  };
}
