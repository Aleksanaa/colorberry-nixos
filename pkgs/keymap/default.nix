{
  runCommand,
  ckbcomp,
  libxkbcommon,
  xkeyboard_config,
}:

# The evdev rules append inet(evdev) after the layout, which would take back
# every keycode the Alt layer uses, so the components are named directly
# instead of going through the rules.
runCommand "colorberry-keymap"
  {
    nativeBuildInputs = [
      ckbcomp
      libxkbcommon
    ];
    preferLocalBuild = true;
  }
  ''
    mkdir -p xkb/symbols $out/share/keymaps $out/share/xkb
    cp ${./beepy} xkb/symbols/beepy

    cat > keymap <<'EOF'
    xkb_keymap {
        xkb_keycodes { include "evdev" };
        xkb_types    { include "complete" };
        xkb_compat   { include "complete" };
        xkb_symbols  { include "pc+beepy" };
    };
    EOF

    xkbcli compile-keymap \
      --include $PWD/xkb \
      --include ${xkeyboard_config}/share/X11/xkb \
      --keymap keymap > $out/share/xkb/colorberry.xkb

    ckbcomp -compact \
      -I$PWD/xkb \
      -I${xkeyboard_config}/share/X11/xkb \
      -keycodes evdev \
      -symbols pc+beepy > $out/share/keymaps/colorberry.map

    # The VT resolves Control + cursor to the bare cursor keysym, so the
    # modifier-encoded sequences have to be bound as literal strings.
    cat >> $out/share/keymaps/colorberry.map <<'EOF'
    control keycode 105 = F100
    control keycode 106 = F101
    string F100 = "\033[1;5D"
    string F101 = "\033[1;5C"
    EOF
  ''
