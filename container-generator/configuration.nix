{ pkgs, config, ... }:

let
  bootScript = pkgs.writeScript "boot" ''
    #!/bin/sh
    unshare -m ./${bootScript1}
  '';
  bootScript1 = pkgs.writeScript "boot1" ''
    #!${pkgs.stdenv.shell}
    mkdir -p proc dev
    mount --bind /proc proc/
    #mount --bind /dev dev/
    mount -t tmpfs tmpfs dev/

    pushd dev
    mknod null c 1 3
    mknod zero c 1 5
    mknod full c 1 7
    mknod random c 1 8
    mknod urandom c 1 9

    mknod tty c 5 0
    mkdir net
    mknod net/tun c 10 200
    popd

    chroot . ${config.system.path}/bin/unshare -i -p -u -C ${bootScript2}
  '';
  bootScript2 = pkgs.writeScript "boot" ''
    #!${pkgs.stdenv.shell} -i
    export PATH=${config.system.path}/bin/
    ${bootScript3} &
    echo the pid is $!
    echo $! > /pid
    fg 1
  '';
  bootScript3 = pkgs.writeScript "boot3" ''
    #!${pkgs.stdenv.shell}
    export PATH=${config.system.path}/bin/
    mount -t proc proc /proc
    if [ -f /nix/var/nix/profiles/system/init ]; then
      exec /nix/var/nix/profiles/system/init
    else
      exec /init
    fi
  '';
  enterScript = pkgs.writeScript "boot" ''
    #!${pkgs.stdenv.shell}
    export PATH=${config.system.path}/bin/
    exec nsenter -t $(cat ./pid) -m -u -i -p -C -r -w ${pkgs.bashInteractive}/bin/bash
  '';
  tarball = pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
    storeContents = [
      { object = "${config.system.build.toplevel}/init"; symlink = "/init"; }
      { object = "${pkgs.bashInteractive}/bin/bash"; symlink = "/bash"; }
      { object = enterScript; symlink = "/enter"; }
      { object = bootScript; symlink = "/boot"; }
    ];
    contents = [];
  };
in {
  system.build = {
    inherit bootScript bootScript2 bootScript3 enterScript tarball;
  };
  system.extraSystemBuilderCmds = ''
    cp ${bootScript} $out/boot
    cp ${enterScript} $out/enter
  '';
  boot.isContainer = true;
  networking.hostName = "guest";
  networking.dhcpcd.enable = false;
  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store on the
    # CD in the Nix database in the tmpfs.
    if [ -f /nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
      rm /nix-path-registration
    fi

    # nixos-rebuild also requires a "system" profile and an
    # /etc/NIXOS tag.
    touch /etc/NIXOS
    ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
    rm /boot /enter /init
    ln -sv ./nix/var/nix/profiles/system/boot boot
    ln -sv ./nix/var/nix/profiles/system/enter enter
    ln -sv ./nix/var/nix/profiles/system/init init
    mkdir -pv /etc/nixos/
    if [ ! -f /etc/nixos/configuration.nix ]; then
      cp ${./configuration.nix} /etc/nixos/configuration.nix
    fi
  '';
}
