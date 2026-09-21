final: prev: {
  ubootOrangePiZero2w = final.callPackage ./uboot.nix { };

  uwe5622-firmware = final.callPackage ./uwe5622-firmware.nix { };

  colorberryKernel = final.linux_6_18;

  colorberryDtb = final.callPackage ./dtb.nix {
    kernel = final.colorberryKernel;
  };

  colorberryKernelPackages = (final.linuxPackagesFor final.colorberryKernel).extend (
    kfinal: kprev: {
      sharp-drm = kfinal.callPackage ./sharp-drm.nix { };
      beepy-kbd = kfinal.callPackage ./beepy-kbd.nix { };
      uwe5622 = kfinal.callPackage ./uwe5622.nix { };
    }
  );
}
