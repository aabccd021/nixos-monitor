{
  nixConfig.allow-import-from-derivation = false;

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  outputs =
    { self, ... }@inputs:
    let

      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs {
        projectRootFile = "flake.nix";
        programs.prettier.enable = true;
        programs.nixfmt.enable = true;
        programs.shfmt.enable = true;
        settings.global.excludes = [ "LICENSE" ];
      };

    in

    {

      # packages.x86_64-linux.formatting = treefmtEval.config.build.check self;
      # checks.x86_64-linux.formatting = treefmtEval.config.build.check self;
      # formatter.x86_64-linux = treefmtEval.config.build.wrapper;
      # nixosModules.default = ./nixosConfiguration.nix;
      # devShells.x86_64-linux = pkgs.mkShellNoCC {
      #   buildInputs = [
      #     pkgs.nixd
      #   ];
      # };
    };
}
