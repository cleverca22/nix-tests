{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.kexec.justdoit;
in {
  options = {
    kexec.justdoit = {
      rootDevice = mkOption {
        type = types.str;
        default = "/dev/sda";
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
      luksEncrypt = mkOption {
        type = types.bool;
        default = false;
        description = "encrypt all of zfs and swap";
      };
    };
  };
  config = lib.mkIf true {
    system.build.justdoit = pkgs.writeScriptBin "justdoit" ''
      #!${pkgs.stdenv.shell}

      set -e

      vgchange -a n

      dd if=/dev/zero of=${cfg.rootDevice} bs=512 count=10000
      ${if cfg.luksEncrypt then ''
        sfdisk ${cfg.rootDevice} <<EOF
        label: dos
        device: ${cfg.rootDevice}
        unit: sectors
        ${cfg.rootDevice}1 : size=${toString (2048 * cfg.bootSize)}, type=83
        ${cfg.rootDevice}2 : type=E8
        EOF
        cryptsetup luksFormat ${cfg.rootDevice}2
        cryptsetup open --type luks ${cfg.rootDevice}2 root
        pvcreate /dev/mapper/root
        vgcreate ${cfg.poolName} /dev/mapper/root
        lvcreate -L ${toString cfg.swapSize} --name swap ${cfg.poolName}
        lvcreate -l '100%FREE' --name root ${cfg.poolName}
        export ROOT_DEVICE=/dev/${cfg.poolName}/root
        export SWAP_DEVICE=/dev/${cfg.poolName}/swap
      '' else ''
        sfdisk ${cfg.rootDevice} <<EOF
        label: dos
        device: ${cfg.rootDevice}
        unit: sectors
        ${cfg.rootDevice}1 : size=${toString (2048 * cfg.bootSize)}, type=83
        ${cfg.rootDevice}2 : size=${toString (2048 * cfg.swapSize)}, type=82
        ${cfg.rootDevice}3 : type=83
        EOF
        export ROOT_DEVICE=${cfg.rootDevice}3
        export SWAP_DEVICE=${cfg.rootDevice}2
      ''}

      mkdir -p /mnt

      mkfs.ext4 ${cfg.rootDevice}1 -L NIXOS_BOOT
      mkswap $SWAP_DEVICE -L NIXOS_SWAP
      zpool create -o ashift=12 -o altroot=/mnt -O compression=lz4 ${cfg.poolName} $ROOT_DEVICE
      zfs create -o mountpoint=legacy ${cfg.poolName}/root
      zfs create -o mountpoint=legacy ${cfg.poolName}/home
      zfs create -o mountpoint=legacy ${cfg.poolName}/nix

      swapon $SWAP_DEVICE
      mount -t zfs ${cfg.poolName}/root /mnt/
      mkdir /mnt/{home,nix,boot}
      mount -t zfs ${cfg.poolName}/home /mnt/home/
      mount -t zfs ${cfg.poolName}/nix /mnt/nix/
      mount -t ext4 ${cfg.rootDevice}1 /mnt/boot/

      nixos-generate-config --root /mnt/

      hostId=$(echo $(head -c4 /dev/urandom | od -A none -t x4))
      cp ${./target-config.nix} /mnt/etc/nixos/configuration.nix

      cat > /mnt/etc/nixos/generated.nix <<EOF
      { ... }:
      {
        boot.loader.grub.device = "${cfg.rootDevice}";
        networking.hostId = "$hostId"; # required for zfs use
      ${lib.optionalString cfg.luksEncrypt ''
        boot.initrd.luks.devices = [
          { name = "root"; device = "${cfg.rootDevice}2"; preLVM = true; }
        ];
      ''}
      }
      EOF

      nixos-install -j 4
    '';
    environment.systemPackages = [ config.system.build.justdoit ];
    boot.supportedFilesystems = [ "zfs" ];
  };
}
