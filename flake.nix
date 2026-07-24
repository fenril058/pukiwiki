{
  description = "PukiWiki PHP development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # PukiWiki は composer を使わず、PHP 本体と拡張だけで動く。
        # 必須: mbstring(マルチバイト処理)。任意: gd(画像系プラグイン), exif。
        php = pkgs.php83.buildEnv {
          extensions =
            { enabled, all }:
            enabled
            ++ (with all; [
              mbstring
              gd
              exif
            ]);
          extraConfig = ''
            mbstring.language = Japanese
            display_errors = On
            error_reporting = E_ALL
          '';
        };

        # ローカル確認用の簡易サーバ起動スクリプト(http://localhost:8080)。
        serve = pkgs.writeShellScriptBin "pukiwiki-serve" ''
          exec ${php}/bin/php -S 127.0.0.1:''${1:-8080} -t "$PWD"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            php
            php.packages.composer
            serve
          ];

          shellHook = ''
            echo "PukiWiki dev shell"
            echo "  php: $(php --version | head -n1)"
            echo "  起動: pukiwiki-serve [port]  (既定 8080)"
          '';
        };

        packages.default = php;
      }
    );
}
