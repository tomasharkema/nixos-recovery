{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.boot.recovery;
  defaultSystem = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs;
    };
    modules =
      [
        "${inputs.nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix"
        # ./installer.nix

        (
          {
            lib,
            pkgs,
            config,
            ...
          }: {
            config = {
              boot = {
                supportedFilesystems.zfs = lib.mkForce false;
              };
              system.stateVersion = config.system.nixos.release;
              netboot.squashfsCompression = "zstd -Xcompression-level 22";
              networking.wireless.enable = true;
            };
          }
        )
      ]
      ++ cfg.extraConfigurations;
  };
in {
  options.boot.recovery = {
    enable = lib.mkEnableOption "enable recovery";

    configuration = lib.mkOption {
      default = defaultSystem;
    };

    extraConfigurations = lib.mkOption {
      default = [];
    };

    sign = lib.mkEnableOption "sign";

    install = lib.mkEnableOption "install";

    netboot.enable = lib.mkEnableOption "netboot";
  };

  config = let
    efi = config.boot.loader.efi;
    lanza = config.boot.lanzaboote.pkiBundle;
    nixosDir = "/EFI/nixos";
    entries = {
      "netbootxyz.conf" = ''
        title  netboot.xyz
        efi    /efi/netbootxyz/netboot.xyz.efi
        sort-key netbootxyz
      '';
      "recovery.conf" = ''
        title  NixOS Recovery
        efi    /efi/recovery/recovery.efi
        sort-key nixosrecovery
      '';
    };
    bootMountPoint = efi.efiSysMountPoint;

    configuration = cfg.configuration;
    configurationBuild = configuration.config.system.build;
    toplevel = configurationBuild.toplevel;

    ramdisk = configurationBuild.netbootRamdisk;
    installer = toplevel;
    kernelVersion = configurationBuild.kernel.version;

    configFile = pkgs.writeText "config.json" (builtins.toJSON {
      hostname = "${config.networking.hostName}";
      imageDrv = "${config.system.build.recoveryImage.drvPath}";
      sign = cfg.sign;
      inherit kernelVersion;
    });
  in
    lib.mkIf cfg.enable {
      # pkgs.stdenvNoCC.mkDerivation {
      #   name = "splash.xpm.gz";
      #   src = ./nix-snowflake-rainbow-svg.xpm;

      #   dontUnpack = true;

      #   installPhase = ''
      #     cat $src | gzip -9 > $out
      #   '';
      # };
      environment.systemPackages = [pkgs.recoveryctl];

      system = {
        build = {
          splash = ./nix-snowflake-rainbow-svg.xpm;

          recoveryImage = pkgs.stdenv.mkDerivation {
            name = "recovery.efi";
            src = installer;
            # version = "1.0.0";

            dontPatch = true;

            buildInputs = with pkgs; [systemdUkify];

            # --splash="${config.system.build.splash}" \
            installPhase = ''
              ukify build \
                --linux="${installer}/kernel" \
                --initrd="${ramdisk}/initrd" \
                --uname="${kernelVersion}" \
                --os-release="${installer}/etc/os-release" \
                --cmdline="debug init=${installer}/init" \
                --measure \
                --output=$out
            '';
          };
        };

        activationScripts = lib.mkIf cfg.install {
          recovery.text = let
            recov = pkgs.writeShellScript "recovery.sh" ''

              if ! ${pkgs.diffutils}/bin/diff "${configFile}" "${bootMountPoint}/EFI/recovery/config.json" > /dev/null 2>&1; then
                ${pkgs.coreutils}/bin/install -D "${config.system.build.recoveryImage}" "${bootMountPoint}/EFI/recovery/recovery.efi"
                ${lib.optionalString cfg.sign ''
                ${pkgs.sbctl}/bin/sbctl sign -s "${bootMountPoint}/EFI/recovery/recovery.efi"
              ''}

                ${pkgs.coreutils}/bin/install -D "${configFile}" "${bootMountPoint}/EFI/recovery/config.json"

                ${lib.optionalString cfg.netboot.enable ''
                ${pkgs.coreutils}/bin/install -D "${pkgs.netbootxyz-efi}" "${bootMountPoint}/EFI/netbootxyz/netboot.xyz.efi"
              ''}

                ${lib.optionalString cfg.sign ''
                ${pkgs.sbctl}/bin/sbctl sign -s "${bootMountPoint}/EFI/netbootxyz/netboot.xyz.efi"
              ''}
              fi

              empty_file=$(${pkgs.coreutils}/bin/mktemp)
              ${lib.concatStrings (lib.mapAttrsToList (n: v: let
                  src = "${pkgs.writeText n v}";
                  dest = "${bootMountPoint}/loader/entries/${lib.escapeShellArg n}";
                in ''
                  if ! ${pkgs.diffutils}/bin/diff "${src}" "${dest}" > /dev/null 2>&1; then

                    ${pkgs.coreutils}/bin/install -Dp "${src}" "${dest}"
                    ${pkgs.coreutils}/bin/install -D $empty_file "${bootMountPoint}/${nixosDir}/.extra-files/loader/entries/"${lib.escapeShellArg n}

                  fi
                '')
                entries)}

              BOOT_ENTRY=$(${pkgs.efibootmgr}/bin/efibootmgr --verbose | ${pkgs.gnugrep}/bin/grep NixosRecovery)
              BOOT_ENTRY_CODE="$?"

              if [ $BOOT_ENTRY_CODE -gt 0 ]; then
                BOOT_PART="$(${pkgs.util-linux}/bin/findmnt -J "${bootMountPoint}" | ${pkgs.jq}/bin/jq ".filesystems[0].source" -r)"
                DEVICE="/dev/$(${pkgs.util-linux}/bin/lsblk -no pkname $BOOT_PART)"
                PARTN="$(${pkgs.util-linux}/bin/lsblk -no PARTN $BOOT_PART)"
                ${pkgs.efibootmgr}/bin/efibootmgr -c --index 2 -d $DEVICE -p $PARTN -L NixosRecovery -l '\EFI\recovery\recovery.efi'
              fi

            '';
          in "${recov}";
        };
      };
    };
}
# if ! ${pkgs.diffutils}/bin/diff ${cfg.certificate} /etc/ipa/ca.crt > /dev/null 2>&1; then
#   rm -f /etc/ipa/ca.crt
#   cp ${cfg.certificate} /etc/ipa/ca.crt
# fi

