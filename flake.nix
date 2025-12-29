{
  description = "NixOS Recovery";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];

      perSystem = {pkgs, ...}: {
        packages = rec {
          recoveryctl = pkgs.callPackage ./recoveryctl {};
          default = recoveryctl;
        };
      };

      flake = {
        nixosModules = rec {
          recovery = import ./module;
          default = recovery;
        };

        nixosConfigurations."tester" = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            self = inputs.self;
            inputs = inputs;
          };
          system = "x86_64-linux";
          modules = [
            inputs.self.nixosModules.recovery
            ./tester.nix
          ];
        };

        overlays = rec {
          recovery = final: prev: {
            recoveryctl = inputs.self.packages."${prev.stdenv.hostPlatform.system}".recoveryctl;
          };
          default = recovery;
        };
      };
    };
}
