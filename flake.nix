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
        nixosModules.recovery = {
          config,
          pkgs,
          ...
        }: {
          environment.systemPackages = with pkgs; [recoveryctl];
        };
        overlays = rec {
          recovery = final: prev: {
            recoveryctl = inputs.nixos-recovery.packages."${prev.system}".recoveryctl;
          };
          default = recovery;
        };
      };
    };
}
