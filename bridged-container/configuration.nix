# nixos-rebuild build-vm -I nixos-config=./configuration.nix  -Q -j 8
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ screen tcpdump ];
  containers.test1 = {
    autoStart = true;
    hostBridge = "br0";
    privateNetwork = true;
    localAddress = "10.0.2.16/24";
    config = { ... }: {
      networking.hostName = "test1";
    };
  };
  networking.bridges.br0.interfaces = [ "eth0" ];
  networking.hostName = "host";
  users.users.root.initialPassword = "root";
}
