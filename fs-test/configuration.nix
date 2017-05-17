{ ... }:

let
  pool = "tank";
  volumes = [ "/" "/nix" "/home" ];
in {
  boot.loader.grub.device = "/dev/sda";
  fileSystems = map (v: { device = "${pool}${v}"; mountPoint = v; fsType = "zfs"; }) volumes;
  networking.hostId = "fe1f6cbf";
}
