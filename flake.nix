{
  nixConfig.allow-import-from-derivation = false;

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  outputs =
    { self, ... }@inputs:
    let
      lib = inputs.nixpkgs.lib;

      collectInputs =
        is:
        pkgs.linkFarm "inputs" (
          builtins.mapAttrs (
            name: i:
            pkgs.linkFarm name {
              self = i.outPath;
              deps = collectInputs (lib.attrByPath [ "inputs" ] { } i);
            }
          ) is
        );

      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      nixosModules.systemd-sendmail = ./systemd-sendmail.nix;

      nixosModules.default = {
        imports = [
          nixosModules.systemd-sendmail
        ];
      };

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.prettier.enable = true;
        programs.nixfmt.enable = true;
        programs.shfmt.enable = true;
        settings.formatter.prettier.priority = 1;
        settings.global.excludes = [ "LICENSE" ];
      };

      formatter = treefmtEval.config.build.wrapper;

      devShells.default = pkgs.mkShellNoCC {
        buildInputs = [
          pkgs.nixd
        ];
      };

      generate-services = pkgs.writeShellApplication {
        name = "generate-services";
        text = builtins.readFile ./generate-services.sh;
      };

      packages = devShells // {
        generate-services = generate-services;
        formatting = treefmtEval.config.build.check self;
        formatter = formatter;
        allInputs = collectInputs inputs;
      };

    in

    {

      packages.x86_64-linux = packages // {
        gcroot = pkgs.linkFarm "gcroot" packages;
      };

      checks.x86_64-linux = packages;
      formatter.x86_64-linux = formatter;
      devShells.x86_64-linux = devShells;

      nixosModules = nixosModules;

    };
}
