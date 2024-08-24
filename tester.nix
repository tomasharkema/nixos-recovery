{
  config,
  pkgs,
  self,
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
}
