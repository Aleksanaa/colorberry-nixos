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
  options.hardware.colorberry.console = {
    kmscon = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run kmscon on the VTs instead of the in-kernel console.";
    };

    font = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.terminus_font}/share/consolefonts/ter-112n.psf.gz";
      description = "PSF font to render the console with.";
    };

    fontSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12;
      description = "Target glyph height; a PSF font is only scaled by whole multiples of its own height.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.console.kmscon) {
    assertions = [
      {
        assertion = !config.services.gpm.enable;
        message = "kmscon tracks the pointer itself; set hardware.colorberry.keyboard.trackpadCursor = false to drop gpm.";
      }
    ];

    services.kmscon = {
      enable = true;
      package = pkgs.ghostcon;
      config = {
        font-engine = "psf";
        font-name = cfg.console.font;
        font-size = cfg.console.fontSize;
        xkb-keymap = "${pkgs.colorberry-keymap}/share/xkb/colorberry.xkb";
        mouse = true;
        # The panel has no cursor plane, so the pointer is drawn into the text.
        soft-cursor = true;
      };
    };
  };
}
