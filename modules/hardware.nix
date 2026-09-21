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
  config = lib.mkIf cfg.enable {
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    boot.kernelPackages = lib.mkDefault pkgs.colorberryKernelPackages;

    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    boot.initrd.availableKernelModules = [
      "sunxi_mmc"
      "mmc_block"
    ];

    boot.kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
    ];

    hardware.deviceTree = {
      enable = true;
      name = "colorberry.dtb";
      dtbSource = pkgs.colorberryDtb;
    };

    hardware.enableRedistributableFirmware = lib.mkDefault true;

    powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  };
}
