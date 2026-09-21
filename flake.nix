{
  description = "NixOS system for ColorBerry (OrangePi Zero 2W)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];

      inherit (self.nixosConfigurations.colorberry) config pkgs;
    in
    {
      overlays.default = import ./pkgs;

      nixosModules.default = {
        imports = [ ./modules ];
        nixpkgs.overlays = [ self.overlays.default ];
      };

      nixosConfigurations.colorberry = nixpkgs.lib.nixosSystem {
        modules = [
          self.nixosModules.default
          ./configuration.nix
        ];
      };

      # Always aarch64-linux, built natively. From x86_64 this needs binfmt
      # emulation or an aarch64 builder.
      packages = forAllSystems (_: {
        default = config.system.build.sdImage;
        sdImage = config.system.build.sdImage;
        rootfs = config.sdImage.rootFilesystemImage;
        toplevel = config.system.build.toplevel;

        inherit (pkgs) ubootOrangePiZero2w colorberryDtb uwe5622-firmware;
        inherit (pkgs.colorberryKernelPackages)
          kernel
          sharp-drm
          beepy-kbd
          uwe5622
          ;
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
