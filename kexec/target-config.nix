{ ... }:

{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "@rootDevice@";
  services.openssh.enable = true;
  networking.hostId = "@hostId@"; # required for zfs use
  boot.zfs.devNodes = "/dev"; # fixes some virtualmachine issues
}
