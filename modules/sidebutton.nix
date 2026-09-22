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

    debounce = lib.mkOption {
      type = lib.types.str;
      default = "200ms";
      description = "Debounce period passed to gpiomon.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.sideButton.enable) {
    systemd.services.colorberry-sidebutton = {
      description = "Toggle the display and keyboard backlights from the side button";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.libgpiod ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 5;
      };
      # sharp-drm leaves the line free, so the button is read here and both
      # backlights are driven together.
      script = ''
        display=/sys/module/sharp_drm/parameters/backlit
        keyboard=/sys/firmware/beepy/keyboard_backlight
        while [ ! -e "$display" ] || [ ! -e "$keyboard" ]; do sleep 1; done

        # gpiomon resolves -c as a device name, not a chip label.
        chip=$(gpiodetect | grep -F '[${cfg.sideButton.chip}]' | cut -d' ' -f1)
        if [ -z "$chip" ]; then
          echo "no gpiochip labelled ${cfg.sideButton.chip}:" >&2
          gpiodetect >&2
          exit 1
        fi

        gpiomon -e rising -b pull-up -p ${cfg.sideButton.debounce} \
          -c "$chip" ${toString cfg.sideButton.line} |
        while read -r _; do
          read -r state < "$display"
          if [ "$state" = "1" ]; then
            echo 0 > "$display"
            echo 0 > "$keyboard"
          else
            echo 1 > "$display"
            echo ${toString cfg.keyboard.backlight} > "$keyboard"
          fi
        done
      '';
    };
  };
}
