let
  eval = import <nixpkgs/nixos> { configuration = ./configuration.nix; };
  pkgs = eval.config._module.args.pkgs;
  bootScript = pkgs.writeScript "boot" ''
    #!/bin/sh
    mkdir -p proc
    mount --bind /proc proc/
    chroot . ${eval.config.system.path}/bin/unshare -i -m -p -u -C --fork ${bootScript2}
  '';
  bootScript2 = pkgs.writeScript "boot" ''
    #!${pkgs.stdenv.shell}
    export PATH=${eval.config.system.path}/bin/
    mount -t proc proc /proc
    exec /bash
  '';
  enterScript = pkgs.writeScript "boot" ''
    #!${pkgs.stdenv.shell}
    export PATH=${eval.config.system.path}/bin/
    exec nsenter --pid=/pid_ns --mount=/mount_ns ${pkgs.bashInteractive}/bin/bash
  '';
in rec {
  tarball = pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
    storeContents = [
      { object = "${eval.config.system.build.toplevel}/init"; symlink = "/init"; }
      { object = "${pkgs.bashInteractive}/bin/bash"; symlink = "/bash"; }
      { object = enterScript; symlink = "/enter"; }
      { object = bootScript; symlink = "/boot"; }
    ];
    contents = [];
  };
  cfg = { ... }: {
    services.mingetty.autologinUser = "root";
    virtualisation.memorySize = 2048;
    services.xserver = {
      enable = true;
      displayManager.slim = {
        enable = true;
        autoLogin = true;
        defaultUser = "root";
      };
      desktopManager.xfce.enable = true;
    };
    environment.systemPackages = [ (
      pkgs.writeScriptBin "doit" ''
        cd /root
        mkdir -p t
        mount -t tmpfs none /root/t -o size=2048m
        cd t
        tar -xf ${tarball}/tarball/nixos-system-x86_64-linux.tar.xz
      ''
    ) ];
  };
  test-guest = (import <nixpkgs/nixos> { configuration = cfg; }).vm;
}
