{ ... }:

{
  boot.isContainer = true;
  networking.hostName = "guest";
  networking.dhcpcd.enable = false;
}
