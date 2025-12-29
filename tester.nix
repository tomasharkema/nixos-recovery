{
  config,
  pkgs,
  self,
  ...
}: {
  nixpkgs.overlays = [self.overlays.recovery];
  system.stateVersion = "26.05";
  environment.systemPackages = with pkgs; [git];
  networking.networkmanager.enable = false;
  boot = {
    isContainer = true;
    recovery = {
      enable = true;

      install = true;
    };
  };
}
