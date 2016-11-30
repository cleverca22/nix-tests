{ arch ? "arm-none-eabi" }:
# known to compile:
# arm-none-eabi
# mipsel-unknown-linux-gnu
let
  cross = {
    config = arch;
    libc = null;
  };
  pkgs = import <nixpkgs> { crossSystem = cross; };
in pkgs.buildEnv {
  name = "arm-baremetal";
  paths = [ pkgs.binutilsCross pkgs.gccCrossStageStatic ];
}