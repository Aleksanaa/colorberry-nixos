{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  cfg = config.hardware.colorberry;
in
{
  imports = [ "${modulesPath}/installer/sd-card/sd-image.nix" ];

  config = lib.mkIf cfg.enable {
    sdImage = {
      compressImage = lib.mkDefault false;
      firmwareSize = 16;

      populateFirmwareCommands = "";

      populateRootCommands = ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
          -c ${config.system.build.toplevel} -d ./files/boot
      '';

      # SPL at 8 KiB, ahead of the first partition at 8 MiB.
      postBuildCommands = ''
        dd if=${pkgs.ubootOrangePiZero2w}/u-boot-sunxi-with-spl.bin of=$img \
          bs=1024 seek=8 conv=notrunc
      '';
    };
  };
}
