{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  libghostty-vt,
  systemdLibs,
  libxkbcommon,
  libdrm,
  libGLU,
  libGL,
  freetype,
  fontconfig,
  zlib,
  pango,
  pkg-config,
  docbook_xsl,
  docbook_xml_dtd_42,
  libxslt,
  libgbm,
  ninja,
  ncurses,
  python3,
  check,
  dbus,
  bash,
  inotify-tools,
  buildPackages,
}:

stdenv.mkDerivation {
  pname = "ghostcon";
  version = "10.0.3-unstable-2026-09-28";

  src = fetchFromGitHub {
    owner = "Aleksanaa";
    repo = "ghostcon";
    rev = "dbb819147a929e5ac798d3055f5d4c3bfded768f";
    hash = "sha256-ja6l2j1K8szEhsMQWSZw+hsS45Jid0Z4kXjaKOfH6Os=";
  };

  postPatch = ''
    patchShebangs scripts/terminfo/build_terminfo.py
  '';

  strictDeps = true;
  __structuredAttrs = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [
    meson
    ninja
    docbook_xsl
    pkg-config
    ncurses
    python3
    libxslt
    docbook_xml_dtd_42
  ];

  buildInputs = [
    libGLU
    libGL
    libdrm
    libghostty-vt
    libxkbcommon
    freetype
    fontconfig
    zlib
    pango
    systemdLibs
    libgbm
    check
    dbus
    bash
  ];

  env.PKG_CONFIG_SYSTEMD_SYSTEMDSYSTEMUNITDIR = "${placeholder "out"}/lib/systemd/system";

  outputs = [
    "out"
    "man"
  ];

  postFixup = ''
    substituteInPlace $out/bin/kmscon-launch-gui \
      --replace-fail "inotifywait" "${lib.getExe' inotify-tools "inotifywait"}"
  '';

  meta = {
    description = "KMS/DRM based system console, kmscon fork used on ColorBerry";
    homepage = "https://github.com/Aleksanaa/ghostcon";
    license = lib.licenses.mit;
    mainProgram = "kmscon";
    platforms = lib.platforms.linux;
  };
}
