with import <nixpkgs> {};

let
  eval = import <nixpkgs/nixos> { configuration = ./configuration.nix; };
in pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
  storeContents = [
    { object = "${eval.config.system.build.toplevel}/init"; symlink = "/init"; }
    { object = "${eval.config._module.args.pkgs.bashInteractive}/bin/bash"; symlink = "/bash"; }
  ];
  contents = [];
}
