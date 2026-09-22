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
      default = "/dev/dri/sharp";
      description = "DRM device of the memory LCD, used to draw indicators and the Berry overlay.";
    };

    trackpadCursor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run gpm so the trackpad moves a console cursor and selects text.";
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

    environment.systemPackages = [ config.boot.kernelPackages.symbol-overlay ];

    services.gpm = lib.mkIf cfg.keyboard.trackpadCursor {
      enable = true;
      protocol = "exps2";
    };

    console.keyMap = lib.mkIf cfg.keyboard.keyMap "${config.boot.kernelPackages.beepy-kbd}/share/keymaps/beepy-kbd.map";

    # Alt+I is keycode 142, which is KEY_SLEEP, but we put it to `-`
    services.logind.settings.Login = {
      HandleSuspendKey = lib.mkDefault "ignore";
      HandleSuspendKeyLongPress = lib.mkDefault "ignore";
    };

    systemd.tmpfiles.rules = [
      "w /sys/firmware/beepy/keyboard_backlight - - - - 0"
    ];

    environment.shellAliases = {
      key = "echo keys | sudo tee ${params}/touch_as > /dev/null";
      mouse = "echo mouse | sudo tee ${params}/touch_as > /dev/null";
    };
  };
}
