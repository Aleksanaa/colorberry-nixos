{
  config,
  lib,
  ...
}:

let
  cfg = config.hardware.colorberry;
in
{
  options.hardware.colorberry.battery = {
    designCapacity = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 5000;
      description = ''
        Design capacity of the pack in mAh, as shipped. The keyboard firmware
        cannot report it, so set this to 0 to leave charge levels unexposed.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModprobeConfig = lib.mkIf (cfg.battery.designCapacity != 0) ''
      options beepy-kbd battery_mah=${toString cfg.battery.designCapacity}
    '';

    services.upower = {
      enable = lib.mkDefault true;
      # There is no charger sense and no current reading, so time estimates
      # would be guesses.
      usePercentageForPolicy = true;
      criticalPowerAction = lib.mkDefault "PowerOff";
    };
  };
}
