{
  config,
  lib,
  ...
}:

let
  cfg = config.hardware.colorberry;
  params = "/sys/module/beepy_kbd/parameters";
in
{
  options.hardware.colorberry.keyboard = {
    touchMode = lib.mkOption {
      type = lib.types.enum [
        "mouse"
        "keys"
      ];
      default = "mouse";
      description = "Whether the trackpad sends mouse events or arrow keys.";
    };

    touchActivation = lib.mkOption {
      type = lib.types.enum [
        "always"
        "click"
      ];
      default = "always";
      description = "Whether the trackpad is always active or only after clicking it.";
    };

    backlight = lib.mkOption {
      type = lib.types.ints.between 0 255;
      default = 255;
      description = "Keyboard backlight brightness used when the backlight is on.";
    };

    drmDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/dri/card1";
      description = "DRM device of the memory LCD, used to draw keyboard indicators.";
    };

    keyMap = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use the beepy console keymap.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [ config.boot.kernelPackages.beepy-kbd ];
    boot.kernelModules = [ "beepy-kbd" ];

    boot.extraModprobeConfig = ''
      options beepy-kbd sharp_path=${cfg.keyboard.drmDevice} touch_as=${cfg.keyboard.touchMode} touch_act=${cfg.keyboard.touchActivation}
    '';

    console.keyMap = lib.mkIf cfg.keyboard.keyMap "${config.boot.kernelPackages.beepy-kbd}/share/keymaps/beepy-kbd.map";

    systemd.tmpfiles.rules = [
      "w /sys/firmware/beepy/keyboard_backlight - - - - 0"
    ];

    environment.shellAliases = {
      key = "echo keys | sudo tee ${params}/touch_as";
      mouse = "echo mouse | sudo tee ${params}/touch_as";
    };
  };
}
