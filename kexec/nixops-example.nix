{
  machine1 = {
    # if the root device is diferent, update it here
    boot.loader.grub.devices = [ "/dev/sda" ];
    deployment = {
      targetEnv = "none";
      targetHost = "192.168.2.160";
    };
    services.openssh.enable = true;
    fileSystems = {
      # if you change the pool name, update it here
      "/" = { fsType = "zfs"; device = "tank/root"; };
      "/home" = { fsType = "zfs"; device = "tank/home"; };
      "/nix" = { fsType = "zfs"; device = "tank/nix"; };
      "/boot" = { fsType = "ext4"; label = "NIXOS_BOOT"; };
    };
    swapDevices = [
      { label = "NIXOS_SWAP"; }
    ];
    networking.hostId = "1d27723e"; # must be copied from the one justdoit randomly generated
  };
}
