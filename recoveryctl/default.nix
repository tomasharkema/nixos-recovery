{
  buildGoModule,
  efibootmgr,
  makeWrapper,
  lib,
}:
buildGoModule rec {
  pname = "recoveryctl";
  version = "0.0.1";

  src = ./.;

  vendorHash = "sha256-THOTzWban6ZdGYV+qEH8AAyddvtHhPOekCamehXxHLY=";

  CGO_ENABLED = 1;

  nativeBuildInputs = [makeWrapper efibootmgr];

  postFixup = ''
    wrapProgram $out/bin/recoveryctl \
      --set PATH ${lib.makeBinPath [
      efibootmgr
    ]}
  '';
}
