final: prev: {
  ubootOrangePiZero2w = final.callPackage ./uboot.nix { };

  uwe5622-firmware = final.callPackage ./uwe5622-firmware.nix { };

  ghostcon = final.callPackage ./ghostcon.nix {
    # ghostcon predates the libghostty-vt 2026-08-06 API break
    libghostty-vt = final.callPackage ./libghostty-vt { };
  };

  colorberry-keymap = final.callPackage ./keymap { };

  colorberry-sidebutton = final.callPackage ./colorberry-sidebutton { };

  colorberryKernel = final.linux_6_18;

  colorberryDtb = final.callPackage ./dtb {
    kernel = final.colorberryKernel;
  };

  colorberryKernelPackages = (final.linuxPackagesFor final.colorberryKernel).extend (
    kfinal: kprev: {
      sharp-drm = kfinal.callPackage ./sharp-drm { };
      beepy-kbd = kfinal.callPackage ./beepy-kbd { };
      uwe5622 = kfinal.callPackage ./uwe5622.nix { };
      symbol-overlay = final.callPackage ./symbol-overlay.nix { inherit (kfinal) beepy-kbd; };
    }
  );
}
