{ pkgs, lib, config, ... }:

let
  zfsUser = if config.boot.zfs.enableUnstable then pkgs.zfsUnstable else pkgs.zfs;
  newcfg = pkgs.runCommand "newcfg" {} ''
    cp -vir ${zfsUser}/etc/zfs/zed.d/ $out
    chmod +w $out/zed.rc
    cat >> $out/zed.rc <<EOF
    ZED_EMAIL="user@example.com"
    EOF
  '';
in {
  fileSystems."/" = { device = "poolname/root"; fsType = "zfs"; };
  networking.hostId = "fe1f6cbf";
  boot.loader.grub.device = "nodev";
  environment.etc."zfs/zed.d".source = lib.mkForce newcfg;
}
