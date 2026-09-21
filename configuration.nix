{ lib, pkgs, ... }:

{
  hardware.colorberry.enable = true;

  networking.hostName = "colorberry";
  networking.networkmanager.enable = true;

  time.timeZone = lib.mkDefault "UTC";

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

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = lib.mkDefault true;
  };

  environment.systemPackages = with pkgs; [
    doggo
    git
    helix
    htop
    iperf
    mtr
    nmap
    speedtest-go
    tmux
    tree
    pfetch
  ];

  documentation = {
    enable = true;
    man.enable = true;
  };

  environment.variables.NIX_REMOTE = "daemon";

  nix = {
    channel.enable = false;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "root" ];
      substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
    };
  };

  system.stateVersion = "25.11";
}
