{
  lib,
  stdenv,
  fetchFromGitHub,
  libdrm,
  beepy-kbd,
}:

stdenv.mkDerivation {
  pname = "symbol-overlay";
  version = "0-unstable-2024-04-25";

  src = fetchFromGitHub {
    owner = "ardangelo";
    repo = "beepy-symbol-overlay";
    rev = "910b9f59c2bbe5e7f33725370ceff0a4c18777af";
    hash = "sha256-DdSc2BLaoRcdUTBuUDyHkHwEGtbGwl52VX2sIK5Y1I4=";
  };

  # beepy-kbd calls the helper without --keymap, so the default has to resolve.
  postPatch = ''
    substituteInPlace src/main.cpp \
      --replace-fail /usr/share/kbd/keymaps/beepy-kbd.map \
        ${beepy-kbd}/share/keymaps/beepy-kbd.map
    substituteInPlace Makefile --replace-fail '$(CXX) -static $^' '$(CXX) $^'
    sed -i '1a #include <cstdint>' src/PSF.hpp
  '';

  buildInputs = [ libdrm ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    install -Dm555 symbol-overlay $out/bin/symbol-overlay
    runHook postInstall
  '';

  meta = {
    description = "Keymap overlay helper for the ColorBerry memory LCD";
    homepage = "https://github.com/ardangelo/beepy-symbol-overlay";
    mainProgram = "symbol-overlay";
    platforms = lib.platforms.linux;
  };
}
