{ buildUBoot, armTrustedFirmwareAllwinnerH616 }:

buildUBoot {
  defconfig = "orangepi_zero2w_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];
  env.BL31 = "${armTrustedFirmwareAllwinnerH616}/bl31.bin";
  filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];
}
