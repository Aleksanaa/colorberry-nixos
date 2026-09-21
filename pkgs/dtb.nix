{
  stdenv,
  dtc,
  kernel,
}:

stdenv.mkDerivation {
  name = "colorberry-dtb";

  src = ../dts;

  nativeBuildInputs = [ dtc ];

  postUnpack = ''
    tar -xf ${kernel.src} --strip-components=1 --wildcards \
      '*/arch/arm64/boot/dts/allwinner/*' \
      '*/include/dt-bindings/*'
  '';

  buildPhase = ''
    runHook preBuild
    $CC -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp \
      -I ../arch/arm64/boot/dts/allwinner \
      -I ../include \
      colorberry.dts -o colorberry.dts.pp
    dtc -I dts -O dtb -@ -o colorberry.dtb colorberry.dts.pp
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 colorberry.dtb $out/colorberry.dtb
    runHook postInstall
  '';
}
