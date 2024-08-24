{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  # pre-commit.hooks.shellcheck.enable = true;

  packages = with pkgs; [efibootmgr];
}
