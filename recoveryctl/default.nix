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

  vendorHash = "sha256-HtIUGfo8Q75JMsnD5X3kGrB18BBYPBMbJ70bhy32vDU=";

  env.CGO_ENABLED = 1;

  nativeBuildInputs = [makeWrapper efibootmgr];

  postFixup = ''
    wrapProgram $out/bin/recoveryctl \
      --set PATH ${lib.makeBinPath [
      efibootmgr
    ]}
  '';
}
