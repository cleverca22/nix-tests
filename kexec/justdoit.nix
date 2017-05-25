{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.kexec.justdoit;
in {
  options = {
    kexec.justdoit = {
      rootDevice = mkOption {
        type = types.str;
        default = "/dev/vda";
        description = "the root block device that justdoit will nuke from orbit and force nixos onto";
      };
      bootSize = mkOption {
        type = types.int;
        default = 256;
        description = "size of /boot in mb";
      };
      swapSize = mkOption {
        type = types.int;
        default = 1024;
        description = "size of swap in mb";
      };
      poolName = mkOption {
        type = types.str;
        default = "tank";
        description = "zfs pool name";
      };
    };
  };
  config = lib.mkIf true {
    system.build.justdoit = pkgs.writeScriptBin "justdoit" ''
      #!${pkgs.stdenv.shell}

      set -e

      dd if=/dev/zero of=${cfg.rootDevice} bs=512 count=10000
      sfdisk ${cfg.rootDevice} <<EOF
      label: dos
      device: ${cfg.rootDevice}
      unit: sectors
      ${cfg.rootDevice}1 : size=${toString (2048 * cfg.bootSize)}, type=83
      ${cfg.rootDevice}2 : size=${toString (2048 * cfg.swapSize)}, type=82
      ${cfg.rootDevice}3 : type=83
      EOF

      mkdir -p /mnt

      mkfs.ext4 ${cfg.rootDevice}1 -L NIXOS_BOOT
      mkswap ${cfg.rootDevice}2 -L NIXOS_SWAP
      zpool create -o ashift=12 -o altroot=/mnt -O compression=lz4 ${cfg.poolName} ${cfg.rootDevice}3
      zfs create -o mountpoint=legacy ${cfg.poolName}/root
      zfs create -o mountpoint=legacy ${cfg.poolName}/home
      zfs create -o mountpoint=legacy ${cfg.poolName}/nix

      swapon ${cfg.rootDevice}2
      mount -t zfs ${cfg.poolName}/root /mnt/
      mkdir /mnt/{home,nix,boot}
      mount -t zfs ${cfg.poolName}/home /mnt/home/
      mount -t zfs ${cfg.poolName}/nix /mnt/nix/
      mount -t ext4 ${cfg.rootDevice}1 /mnt/boot/

      nixos-generate-config --root /mnt/

      hostId=$(echo $(head -c4 /dev/urandom | od -A none -t x4))
      sed -e s/@hostId@/$hostId/ -e s/@rootDevice@/${cfg.rootDevice}/ < ${./target-config.nix} > /mnt/etc/nixos/configuration.nix

      nixos-install -j 4
    '';
    environment.systemPackages = [ config.system.build.justdoit ];
  };
}
