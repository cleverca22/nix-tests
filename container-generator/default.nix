let
  eval = import <nixpkgs/nixos> { configuration = ./configuration.nix; };
  pkgs = eval.config._module.args.pkgs;
  enterScript = pkgs.writeScript "enter" ''
    #!${pkgs.stdenv.shell}
    export PATH=${eval.config.system.path}/bin/
    exec unshare -p ${eval.config.system.build.toplevel}/init
  '';
in pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
  storeContents = [
    { object = "${eval.config.system.build.toplevel}/init"; symlink = "/init"; }
    { object = "${pkgs.bashInteractive}/bin/bash"; symlink = "/bash"; }
    { object = enterScript; symlink = "/enter"; }
  ];
  contents = [];
}
