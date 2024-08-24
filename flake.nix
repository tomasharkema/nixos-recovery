{
  description = "NixOS Recovery";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    self,
    ...
  } @ inputs:
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

        nixosConfigurations."tester" = nixpkgs.lib.nixosSystem {
          specialArgs = inputs;
          system = "x86_64-linux";
          modules = [
            self.nixosModules.recovery
            ({
              config,
              pkgs,
              ...
            }: {
              nixpkgs.overlays = [self.overlays.recovery];
              system.stateVersion = "24.11";
              environment.systemPackages = with pkgs; [git];
              boot = {
                isContainer = true;
                recovery = {
                  enable = true;

                  install = true;
                };
              };
            })
          ];
        };

        overlays = rec {
          recovery = final: prev: {
            recoveryctl = self.packages."${prev.system}".recoveryctl;
          };
          default = recovery;
        };
      };
    };
}
