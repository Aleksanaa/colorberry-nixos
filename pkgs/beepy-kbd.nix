{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

stdenv.mkDerivation {
  pname = "beepy-kbd";
  version = "0-unstable-2024-10-14";

  src = fetchFromGitHub {
    owner = "hyphenlee";
    repo = "beepy-kbd-orangepi";
    rev = "af8b959e23c65a5f972ee76904b2c59d853f228c";
    hash = "sha256-eue7QzpgTpsmQuImOTWX6TNwlFNG/7ntZkhunXXfJ6Q=";
  };

  patches = [ ../patches/beepy-kbd-alt-space-meta-jk.patch ];

  # The driver spawns the overlay helper by absolute path; /sbin does not exist.
  postPatch = ''
    substituteInPlace Makefile --replace-fail 'dtb-y += beepy-kbd.dtbo' ""
    substituteInPlace src/input_meta.c src/input_modifiers.c \
      --replace-fail /sbin/symbol-overlay /run/current-system/sw/bin/symbol-overlay
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
  ];

  buildFlags = [ "modules" ];
  installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
  installTargets = [ "modules_install" ];

  postInstall = ''
    install -Dm444 beepy-kbd.map $out/share/keymaps/beepy-kbd.map
  '';

  meta = {
    description = "Keyboard driver for the BB Q20 keyboard on ColorBerry";
    homepage = "https://github.com/hyphenlee/beepy-kbd-orangepi";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
