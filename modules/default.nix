{ lib, ... }:

{
  imports = [
    ./hardware.nix
    ./display.nix
    ./keyboard.nix
    ./battery.nix
    ./sidebutton.nix
    ./wireless.nix
    ./sd-image.nix
  ];

  options.hardware.colorberry.enable = lib.mkEnableOption "ColorBerry (OrangePi Zero 2W) support";
}
