{
  lib,
  buildGoModule,
}:

buildGoModule {
  pname = "colorberry-sidebutton";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-7mZCx07AMuv3THlhVLoWzal5w9ZsjR05PbkE5RVUCVE=";

  meta = {
    description = "Toggle the ColorBerry display and keyboard backlights from the side button";
    mainProgram = "colorberry-sidebutton";
    platforms = lib.platforms.linux;
  };
}
