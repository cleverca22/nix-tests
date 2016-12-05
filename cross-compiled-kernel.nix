# export NIX_LDFLAGS="${NIX_LDFLAGS} -lncurses"
# make bcm2709_defconfig
# make gconfig
# time make CROSS_COMPILE=arm-none-eabi- -j 8

with import <nixpkgs> {};
let
  pkgs2 = import <nixpkgs> {
    crossSystem = {
      config = "arm-none-eabi";
      libc = null;
    };
  };
in runCommand "kernel" {
  buildInputs = [ pkgs2.binutilsCross pkgs2.gccCrossStageStatic gcc ncurses pkgconfig gtk2 glib gnome2.libglade bc ];
  ARCH = "arm";
} ""
