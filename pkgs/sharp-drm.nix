{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

stdenv.mkDerivation {
  pname = "sharp-drm";
  version = "0-unstable-2026-08-29";

  src = fetchFromGitHub {
    owner = "hyphenlee";
    repo = "jdi-drm-rpi";
    rev = "2b5eeabefc6cea68b3d4c411636feceeb31d008e";
    hash = "sha256-ZhI/IOiuPyiazwHDywXqsiik/5FnWd3YleiDSQjZZ/s=";
  };

  sourceRoot = "source/orangepi-src";

  patches = [ ../patches/sharp-drm-linux-6.18.patch ];

  postPatch = "substituteInPlace Makefile --replace-fail 'dtb-y += sharp-drm.dtbo' ''";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
  ];

  buildFlags = [ "modules" ];
  installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
  installTargets = [ "modules_install" ];

  meta = {
    description = "DRM driver for the JDI/Sharp memory LCD on ColorBerry";
    homepage = "https://github.com/hyphenlee/jdi-drm-rpi";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
