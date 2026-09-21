{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
  uwe5622-firmware,
}:

stdenv.mkDerivation {
  pname = "uwe5622";
  version = "0-unstable-2026-08-15";

  src = fetchFromGitHub {
    owner = "ValdikSS";
    repo = "uwe5622";
    rev = "d6bec7538a0b4b67e35715ad71eaa056555524cb";
    hash = "sha256-tKR8kHWy157LmVQUJvhI3d9Uy/fKfDUGGalFSxa7yHs=";
  };

  postPatch = "substituteInPlace Makefile --replace-fail /bin/pwd pwd";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
    # Selects the Allwinner variant; everything else is a compile-time switch
    # in unisocwcn/Makefile, so no uwe-bsp device tree node is needed.
    "CONFIG_AW_WIFI_DEVICE_UWE5622=y"
    "CONFIG_WLAN_UWE5622=m"
    "CONFIG_SPRDWL_NG=m"
    "CONFIG_TTY_OVERY_SDIO=m"
    # The drivers open these paths directly instead of using request_firmware.
    "UNISOC_FW_PATH_CONFIG=${uwe5622-firmware}/lib/firmware/uwe5622/"
    "UNISOC_WIFI_CUS_CONFIG=${uwe5622-firmware}/lib/firmware/uwe5622"
  ];

  buildFlags = [ "modules" ];
  installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
  installTargets = [ "modules_install" ];

  meta = {
    description = "Unisoc uwe5622 WiFi/Bluetooth drivers";
    homepage = "https://github.com/ValdikSS/uwe5622";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
