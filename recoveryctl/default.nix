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

  vendorHash = "sha256-Qx6m4jauCcK5ADB9RSf770Pv4XMZEcnvXaZZW2/F9hk=";

  CGO_ENABLED = 1;

  nativeBuildInputs = [makeWrapper efibootmgr];

  postFixup = ''
    wrapProgram $out/bin/recoveryctl \
      --set PATH ${lib.makeBinPath [
      efibootmgr
    ]}
  '';
}
