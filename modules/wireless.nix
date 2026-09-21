{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.colorberry;
in
{
  options.hardware.colorberry.wireless = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Load the uwe5622 WiFi/Bluetooth drivers.";
    };

    bluetooth = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Load the Bluetooth tty driver. It exposes /dev/stty_bt, which still needs a userspace attach step.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.wireless.enable) {
    boot.extraModulePackages = [ config.boot.kernelPackages.uwe5622 ];

    # uwe5622_bsp_sdio brings the chip up and must be loaded first.
    boot.kernelModules = [
      "uwe5622_bsp_sdio"
      "sprdwl_ng"
    ]
    ++ lib.optional cfg.wireless.bluetooth "sprdbt_tty";

    hardware.firmware = [ pkgs.uwe5622-firmware ];
  };
}
