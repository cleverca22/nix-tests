{ pkgs, lib, ... }:

with lib;

{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-kde.nix> ];
  environment.systemPackages = with pkgs; [ teamspeak_client ];
  services = {
    xserver.autorun = mkOverride 49 true;
    toxvpn = {
      enable = true;
      localip = "192.168.123.45";
      auto_peers = [ "dd51f5f444b63c9c6d58ecf0637ce4c161fe776c86dc717b2e209bc686e56a5d2227dfee1338" ];
    };
  };
  environment.etc."wpa_supplicant.conf".text = ''
    network={
        ssid="network name"
        psk="network password"
    }
  '';
  networking.wireless.enable = true;
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}
