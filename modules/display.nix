{
  config,
  lib,
  ...
}:

let
  cfg = config.hardware.colorberry;
  params = "/sys/module/sharp_drm/parameters";
  bit = b: if b then "1" else "0";
in
{
  options.hardware.colorberry.display = {
    dither = lib.mkOption {
      type = lib.types.ints.between 0 4;
      default = 0;
      description = "Dithering level of the colour memory LCD. 0 disables dithering, 4 is best for images.";
    };

    backlight = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Turn the display backlight on at boot. The side button toggles it at runtime.";
    };

    overlays = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Let the keyboard driver draw indicator overlays on the display.";
    };

    consoleFont = lib.mkOption {
      type = lib.types.str;
      default = "VGA8x8";
      description = "fbcon font to use on the 400x240 panel.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [ config.boot.kernelPackages.sharp-drm ];
    boot.kernelModules = [ "sharp-drm" ];

    boot.extraModprobeConfig = ''
      options sharp-drm dither=${toString cfg.display.dither} backlit=${bit cfg.display.backlight} overlays=${bit cfg.display.overlays}
    '';

    boot.kernelParams = [
      "fbcon=font:${cfg.display.consoleFont}"
      "fbcon=map:10"
    ];

    environment.shellAliases = {
      d0 = "echo 0 | sudo tee ${params}/dither";
      d3 = "echo 3 | sudo tee ${params}/dither";
      d4 = "echo 4 | sudo tee ${params}/dither";
      b = "echo 1 | sudo tee ${params}/backlit";
      bn = "echo 0 | sudo tee ${params}/backlit";
    };
  };
}
