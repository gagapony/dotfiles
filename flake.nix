{
  description = "Gabriel's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
    in
    {
      packages = nixpkgs.lib.genAttrs systems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
        zsh-config = pkgs.stdenv.mkDerivation rec {
          pname = "zsh-config";
          version = "1.0.0";

          src = pkgs.fetchFromGitHub {
            owner = "romkatv";
            repo = "powerlevel10k";
            rev = "8fa10f43a0f65a5e15417128be63e68e1d5b1f66";
            sha256 = "sha256-isxgLWpbBuNoETXCOlJ4nwGSxMwCjoVF5D0dMZWtM5s=";
          };

          dontBuild = true;

          installPhase = ''
            mkdir -p $out/config/custom/themes/powerlevel10k
            cp -r ${self}/zsh/.p10k.zsh $out/config/custom/themes/
            cp -r ./* $out/config/custom/themes/powerlevel10k
            rm -rf $out/config/custom/themes/powerlevel10k/LICENSE
            rm -rf $out/config/custom/themes/powerlevel10k/README.md
          '';
        };

        nvim-config = pkgs.stdenv.mkDerivation rec {
          pname = "nvim-config";
          version = "1.0.0";
          src = self;
          dontBuild = true;
          installPhase = ''
            mkdir -p $out/config
            cp -r ./nvim $out/config/
            rm -rf $out/config/nvim/README.md
          '';
        };

        tmux-config = pkgs.stdenv.mkDerivation rec {
          pname = "tmux-config";
          version = "1.0.0";

          src = pkgs.fetchFromGitHub {
            owner = "gpakosz";
            repo = ".tmux";
            rev = "4cb811769abe8a2398c7c68c8e9f00e87bad4035";
            sha256 = "sha256-e7Ymv3DD7FY2i7ij9woZ6o/edJGbEfm2K8wrD2H43Yk=";
          };

          dontBuild = true;

          installPhase = ''
            mkdir -p $out/config
            cp -r ${self}/tmux/.tmux.conf.local $out/config
            cp -r ./.tmux.conf $out/config
            rm -rf $out/config/README.md
          '';
        };
      });
    };
}
