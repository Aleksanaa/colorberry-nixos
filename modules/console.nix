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

    fontEngine = lib.mkOption {
      type = lib.types.enum [
        "freetype"
        "psf"
        "unifont"
      ];
      default = "freetype";
      description = ''
        Where glyphs come from. All three draw 1-bit bitmaps, so all three stay
        sharp on the panel. freetype reads Terminus' own bitmap strike and keeps
        its full repertoire; psf reads the console build of the same font, which
        is smaller but stripped to 256 glyphs; unifont is built in and is the
        only one that reaches CJK, at the cost of an 8x16 cell.
      '';
    };

    font = lib.mkOption {
      type = lib.types.str;
      default =
        if cfg.console.fontEngine == "psf" then
          "${pkgs.terminus_font}/share/consolefonts/ter-112n.psf.gz"
        else
          "Terminus";
      description = "Family name under freetype, path to a PSF under psf. Unifont carries its own.";
    };

    fontSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12;
      description = "Glyph height in pixels. Bitmap fonts only scale by whole multiples of their own height.";
    };

    boldSynthesize = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Draw bold by thickening the regular face. Terminus ships a bold face
        byte-identical to its regular one at 6x12, because six pixels leave no
        room to thicken a stem, so without this bold text is indistinguishable
        from plain. Only freetype reads it; psf always thickens.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.console.kmscon) {
    assertions = [
      {
        assertion = !config.services.gpm.enable;
        message = "kmscon tracks the pointer itself; set hardware.colorberry.keyboard.trackpadCursor = false to drop gpm.";
      }
    ];

    fonts.packages = lib.mkIf (cfg.console.fontEngine == "freetype") [ pkgs.terminus_font ];

    services.kmscon = {
      enable = true;
      package = pkgs.ghostcon;
      config = {
        font-engine = cfg.console.fontEngine;
        font-size = cfg.console.fontSize;
        font-bold-synthesize = cfg.console.boldSynthesize;
        xkb-keymap = "${pkgs.colorberry-keymap}/share/xkb/colorberry.xkb";
        mouse = true;
        # The panel has no cursor plane, so the pointer is drawn into the text.
        soft-cursor = true;
      }
      // lib.optionalAttrs (cfg.console.fontEngine != "unifont") {
        font-name = cfg.console.font;
      };
    };
  };
}
