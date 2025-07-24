{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    naersk,
    fenix,
  }:
    utils.lib.eachDefaultSystem
    (
      system: let
        name = "masklint";
        version = "latest";
        # https://discourse.nixos.org/t/using-nixpkgs-legacypackages-system-vs-import/17462/7
        pkgs = nixpkgs.legacyPackages.${system};
        toolchain = fenix.packages.${system}.fromToolchainFile {
          file = ./rust-toolchain.toml;
          sha256 = "sha256-R0F0Risbr74xg9mEYydyebx/z0Wu6HI0/KWwrV30vZo=";
        };
        naersk' = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };
      in
        with pkgs; rec {
          packages = {
            default = packages.${name};
            "${name}" = naersk'.buildPackage {
              inherit name version;
              src = ./.;
            };
          };

          apps = {
            default = apps.${name};
            "${name}" = utils.lib.mkApp {
              drv = packages.default;
              exePath = "/bin/${name}";
            };
          };

          devShell = mkShellNoCC {
            packages = [
              # rust
              rustup
              cargo-audit
              cargo-outdated
              cargo-cross
              cargo-edit

              mask
              yq-go
              ripgrep
              fd
              goreleaser
              svu
              commitlint-rs
              syft
              cosign

              # shells
              shellcheck

              # python
              python311
              ruff

              # ruby
              ruby_3_2
              rubyPackages_3_2.rubocop
            ];

            # see https://github.com/cross-rs/cross/issues/1241
            CROSS_CONTAINER_OPTS = "--platform linux/amd64";
          };
        }
    );
}
