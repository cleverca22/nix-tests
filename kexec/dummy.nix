let
  pkgs = import <nixpkgs> { config = {}; };
  netboot = let
    build = (import (pkgs.path + "/nixos/lib/eval-config.nix") {
      system = "x86_64-linux";
      modules = [
        (pkgs.path + "/nixos/modules/installer/netboot/netboot-minimal.nix")
        ./justdoit.nix
        ./test.nix
      ];
    }).config.system.build;
  in pkgs.symlinkJoin {
    name = "netboot";
    paths = with build; [ netbootRamdisk kernel netbootIpxeScript ];
  };
in netboot
