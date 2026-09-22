# NixOS for ColorBerry


<p align="center">
  <img width="360" height="480" alt="image" src="https://github.com/user-attachments/assets/12653c46-5eab-4d23-95df-b6df6268bece" />

</p>

Pure NixOS for colorberry, 6.18 LTS kernel (latest LTS at the time of writing), pretty much everything works the same way as stock Debian image.

Using & modifying this system requires understanding of Nix/NixOS. [NixOS Setup Guide - Configuration / Home-Manager / Flakes](https://www.youtube.com/watch?v=AGVXJ-TIv3Y&t=1109s) walks through the basics; you can also discuss in https://matrix.to/#/#users:nixos.org or https://t.me/nixos_zhcn.

## Installation

Firstly, you need to get an ARM64 Linux machine with Nix installed. See https://nixos.org/download/ for how to install Nix. If you are using a x86_64 Linux machine, you can enable aarch64 emulation by adding this in `/etc/nix/nix.conf`:

```
extra-platforms = aarch64-linux arm-linux
extra-sandbox-paths = /usr/bin/qemu-aarch64-static
```

For x86_64 NixOS, just `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`.

> It's possible to cross compile the whole image, however I didn't support this because 1. Sometimes Nixpkgs cross chain breaks without timely fixes; 2. If you want to run `nixos-rebuild` on host, that would copy the world since cross and local are completely different worlds.

Then just build the image:

```
nix build .#sdImage
```

Write the image to SD card (Do check which device is SD card!!!)

```
dd if=./result/sd-image/nixos-image-sd-card-*-aarch64-linux.img of=/dev/sda
```

Put the card back. Reboot. The default username is `colorberry` and password is `colorberry` too.

## Modification

`configuration.nix` hosts the default config for our SD image. You can modify it and rebuild to get a custom image. But in the long run, you need to create your own config.

### Your own flake

A minimal standalone flake should be like:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    colorberry.url = "github:Aleksanaa/colorberry-nixos";
    colorberry.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, colorberry, ... }:
    {
      nixosConfigurations.colorberry = nixpkgs.lib.nixosSystem {
        modules = [
          colorberry.nixosModules.default
          (
            { ... }:
            {
              hardware.colorberry.enable = true;

              networking.hostName = "colorberry";
              networking.networkmanager.enable = true;

              users.users.colorberry = {
                isNormalUser = true;
                initialPassword = "colorberry";
                extraGroups = [
                  "wheel"
                  "networkmanager"
                  "video"
                  "input"
                  "dialout"
                ];
              };

              services.openssh.enable = true;

              system.stateVersion = "26.05";
            }
          )
        ];
      };
    };
}
```

`hardware.colorberry.enable` sets
`nixpkgs.hostPlatform`, the kernel, the device tree, extlinux, and turns on the display, keyboard, side button and WiFi with working defaults. `video` and `input` group lets user talk to the panel and the keyboard without root.

Build the image from that flake with:

```
nix build .#nixosConfigurations.colorberry.config.system.build.sdImage
```

Or on a live system already with an installation:

```
nixos-rebuild switch --sudo --flake .#colorberry
```

### Options

Read `./modules/*.nix` for the full set of options; it should be self-explanatory.
