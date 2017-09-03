{ pkgs, ... }:

let
  dummy_firmware = writeTextFile {
    name = "brcmfmac4356-pcie.txt";
    text = builtins.readFile ./brcmfmac4356-pcie.txt;
    destination = "/lib/firmware/brcm/brcmfmac4356-pcie.txt";
  };
in {
  hardware.firmware = [ dummy_firmware ];
}
