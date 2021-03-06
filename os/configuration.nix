{ config, pkgs, lib, ... }:

let
  appvm = (import ../default.nix);
in {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ./target.nix
    #./hardware-configuration.nix
  ];

  time.timeZone = "UTC";

  boot.loader.systemd-boot.enable = true;

  # You can not use networking.networkmanager with networking.wireless
  networking.wireless.enable = false;

  users.users.user = {
    isNormalUser = true;
    initialPassword = "user";   # should be changed right after start
    extraGroups = [ "audio" "libvirtd" ];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemuVerbatimConfig = ''
      namespaces = []
      user = "user"
      group = "users"
    '';
  };

  systemd.user.services."dot-desktop-fuse" = {
    serviceConfig = {
      ExecStart = "${appvm}/bin/dot-desktop-fuse";
      Restart = "on-failure";
    };
    path = [ "/run/wrappers" ];
    wantedBy = [ "default.target" ];
  };

  systemd.user.services."autoballoon" = {
    serviceConfig.StartLimitBurst = 64;
    script = "${appvm}/bin/appvm autoballoon";
  };

  systemd.user.timers."autoballoon" = {
    description = "Autoupdate resolution crutch";
    timerConfig = {
      OnBootSec = "1s";
      OnUnitInactiveSec = "1s";
      Unit = "autoballoon.service";
      AccuracySec = "1us";
    };
    wantedBy = ["timers.target"];
  };

  environment.systemPackages = with pkgs; [
    appvm virtmanager chromium
    # Cache packages required for application VMs
    xmonad-with-packages spice-vdagent bc qemu_test lightdm
  ];

  services.xserver.enable = true;
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = false;            # FIXME
    autoLogin = {
      enable = true;
      user = "user";
    };
  };

  services.xserver.desktopManager.gnome3.enable = true;
}
