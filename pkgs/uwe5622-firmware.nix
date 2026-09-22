{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  rev = "2a9e1c19460401443267926181191d57e3ff175d";

  fetch =
    file: hash:
    fetchurl {
      url = "https://raw.githubusercontent.com/armbian/firmware/${rev}/uwe5622/${file}";
      inherit hash;
    };

  # The chip on the ColorBerry reports id 2355b001 and has a single antenna;
  # unisocwifi builds the RF table name from those.
  files = {
    "wcnmodem.bin" = fetch "wcnmodem.bin" "sha256-EZuHzjCHVzSmdGL3KT+4/oWs8ycP6LeMl4riS+dxWoA=";
    "wifi_2355b001_1ant.ini" =
      fetch "wifi_2355b001_1ant.ini" "sha256-HzxA7CRajQuZrRwjcGWX1t1QCKuAzvt7zBlW78TpOPc=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "uwe5622-firmware";
  version = "0-unstable-${lib.substring 0 7 rev}";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: file: "install -Dm444 ${file} $out/lib/firmware/uwe5622/${name}") files
    )}
    runHook postInstall
  '';

  meta = {
    description = "Unisoc uwe5622 WiFi firmware and RF tables, as shipped by Armbian";
    homepage = "https://github.com/armbian/firmware";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
