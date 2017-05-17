{ ... }:

{
  boot.loader.grub.device = "/dev/sda";
  fileSystems = [
    { device = "pool/root"; mountPoint = "/"; fsType = "zfs"; }
  ];
}
