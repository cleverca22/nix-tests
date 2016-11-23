{ pkgs, lib, config, ... }:

{
  system.build.example = import <nixpkgs/nixos/lib/make-disk-image.nix> {
    inherit pkgs lib config;
    partitioned = true;
    diskSize = 2 * 1024;
  };
  fileSystems."/".device = "/dev/disk/by-label/nixos";
  boot.loader.grub.device = "/dev/vda";
  services.xserver = {
    displayManager.slim.enable = true;
    desktopManager.xfce.enable = true;
    enable = true;
  };
  boot.plymouth.enable = true;
  users.users.root.initialPassword = "root";
}