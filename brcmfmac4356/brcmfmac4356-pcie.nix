{ pkgs, ... }:

let
  dummy_firmware = writeTextFile {
    name = "brcmfmac4356-pcie.txt";
    text = builtins.readFile ./brcmfmac4356-pcie.txt;
    destination = "/lib/firmware/brcm/brcmfmac4356-pcie.txt";
  };
{
  hardware.firmware = [ dummy_firmware ];
}
