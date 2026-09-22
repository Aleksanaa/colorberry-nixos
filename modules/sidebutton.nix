{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.colorberry;
in
{
  options.hardware.colorberry.sideButton = {
    enable = lib.mkEnableOption "side button backlight toggle" // {
      default = true;
    };

    chip = lib.mkOption {
      type = lib.types.str;
      default = "300b000.pinctrl";
      description = "Label of the GPIO chip carrying the side button line.";
    };

    line = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 226;
      description = "Side button line offset on the chip (PH2).";
    };

    edge = lib.mkOption {
      type = lib.types.enum [
        "rising"
        "falling"
        "both"
      ];
      default = "falling";
      description = "Edge that counts as a press. The line rests high, so a press pulls it down.";
    };

    debounce = lib.mkOption {
      type = lib.types.str;
      default = "200ms";
      description = "Ignore further edges for this long after a press.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.sideButton.enable) {
    # sharp-drm leaves the line free, so the button is read here and both
    # backlights are driven together.
    systemd.services.colorberry-sidebutton = {
      description = "Toggle the display and keyboard backlights from the side button";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          (lib.getExe pkgs.colorberry-sidebutton)
          "-chip ${cfg.sideButton.chip}"
          "-line ${toString cfg.sideButton.line}"
          "-edge ${cfg.sideButton.edge}"
          "-debounce ${cfg.sideButton.debounce}"
          "-brightness ${toString cfg.keyboard.backlight}"
        ];
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
