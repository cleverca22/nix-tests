{ ... }:

{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "@rootDevice@";
  services.openssh.enable = true;
  networking.hostId = "@hostId@"; # required for zfs use
  boot.zfs.devNodes = "/dev"; # fixes some virtualmachine issues
  boot.kernelParams = [
    "panic=30" "boot.panic_on_fail" # reboot the machine upon fatal boot issues
  ];
}
