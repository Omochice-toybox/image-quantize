{
  description = "A simple tool to quantize a image by median colors";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-packages = {
      url = "github:Omochice/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      flake-utils,
      nur-packages,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            nur-packages.overlays.default
          ];
        };
        treefmt = treefmt-nix.lib.evalModule pkgs (
          { ... }:
          let
            ruffConfig =
              ./pyproject.toml
              |> builtins.readFile
              |> builtins.fromTOML
              |> builtins.getAttr "tool"
              |> builtins.getAttr "ruff";
          in
          {
            programs = {
              # keep-sorted start block=yes
              formatjson5 = {
                enable = true;
                indent = 2;
              };
              keep-sorted.enable = true;
              nixfmt.enable = true;
              ruff-check = {
                enable = true;
                extendSelect = ruffConfig.lint.select;
              };
              ruff-format = {
                enable = true;
              };
              taplo = {
                enable = true;
              };
              yamlfmt = {
                enable = true;
                settings = {
                  formatter = {
                    type = "basic";
                    retain_line_breaks_single = true;
                  };
                };
              };
              # keep-sorted end
            };
          }
        );
        runAs =
          name: runtimeInputs: text:
          let
            program = pkgs.writeShellApplication {
              inherit name runtimeInputs text;
            };
          in
          {
            type = "app";
            program = "${program}/bin/${name}";
          };
        devPackages = rec {
          # keep-sorted start block=yes
          actions = [
            pkgs.zizmor
            pkgs.actionlint
            pkgs.ghalint
          ];
          renovate = [
            pkgs.renovate
          ];
          uv = [
            pkgs.uv
          ];
          # keep-sorted end
          default = [ treefmt.config.build.wrapper ] ++ actions ++ uv;
        };
      in
      {
        # keep-sorted start block=yes
        apps = {
          check-actions =
            ''
              actionlint
              ghalint run
              zizmor .github/workflows .github/actions
            ''
            |> runAs "check-action" devPackages.actions;
          check-renovate-config =
            ''
              renovate-config-validator --strict
            ''
            |> runAs "check-renovate-config" devPackages.renovate;
        };
        checks = {
          formatting = treefmt.config.build.check self;
        };
        devShells =
          devPackages
          |> pkgs.lib.attrsets.mapAttrs (
            _: packages:
            pkgs.mkShell {
              inherit packages;
            }
          );
        formatter = treefmt.config.build.wrapper;
      }
      # keep-sorted end
    );
}
