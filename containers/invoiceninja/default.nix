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
        pkgs.gnupg
        pkgs.rsync
        pkgs.noto-fonts
        pkgs.wqy_microhei
        pkgs.wqy_zenhei
        pkgs.chromium
        pkgs.busybox
        pkgs.mariadb.client
      ];
    };

    fakeRootCommands = ''
      #!${pkgs.runtimeShell}
      mkdir -p /var/www/.config
      chmod 777 /var/www/.config   # Chrome needs this
    '';
    enableFakechroot = true;

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
        "SNAPPDF_CHROMIUM_PATH=chromium"   # added
      ];
      Healthcheck = {
        Test = [
          "CMD-SHELL"
          "wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1"
        ];
        Interval = 30000000000;   # 30s in nanoseconds
        Timeout = 3000000000;     # 3s
        StartPeriod = 100000000000; # 100s
        Retries = 3;
      };
    };
  };
}
