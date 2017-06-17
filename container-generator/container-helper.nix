{ pkgs, config, ... }:

let
  bootScript = pkgs.writeScript "boot" ''
    #!/bin/sh
    unshare -m .${createMountsScript}
  '';
  createMountsScript = pkgs.writeScript "createMounts" ''
    #!/bin/sh
    mkdir -p proc dev
    mount --bind /proc proc/
    mount -t tmpfs tmpfs dev/
    mkdir -p etc
    touch etc/resolv.conf
    mount --bind /etc/resolv.conf etc/resolv.conf

    cd dev
    mknod null c 1 3
    mknod zero c 1 5
    mknod full c 1 7
    mknod random c 1 8
    mknod urandom c 1 9
    mknod tty c 5 0
    mkdir net
    mknod net/tun c 10 200
    cd ..

    export LC_ALL="C"
    chroot . ${unshareNonMountScript}
  '';
  unshareNonMountScript = pkgs.writeScript "unshareNonMount" ''
    #!${pkgs.stdenv.shell} --noprofile
    export PATH=${config.system.path}/bin
    unshare -i -p -u ${launchInitScript}
  '';
  launchInitScript = pkgs.writeScript "launchInit" ''
    #!${pkgs.stdenv.shell} --noprofile
    set -m
    ${initScript} &
    echo $! > /pid
    fg 1
  '';
  initScript = pkgs.writeScript "initScript" ''
    #!${pkgs.stdenv.shell}
    mount -t proc proc /proc
    if [ -f /nix/var/nix/profiles/system/init ]; then
      exec /nix/var/nix/profiles/system/init
    else
      exec /init
    fi
  '';
  enterScript = pkgs.writeScript "enter" ''
    #!/bin/sh
    exec nsenter -t $(cat ./pid) -m -u -i -p -r -w ${pkgs.bashInteractive}/bin/bash
  '';
  tarball = pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
    storeContents = [
      { object = "${config.system.build.toplevel}/init"; symlink = "/init"; }
      { object = "${pkgs.bashInteractive}/bin/bash"; symlink = "/bash"; }
      { object = enterScript; symlink = "/enter"; }
    ];
    contents = [
      { source = bootScript; target = "/boot"; }
    ];
  };
in {
  system.build = {
    inherit bootScript createMountsScript unshareNonMountScript launchInitScript initScript enterScript tarball;
  };
  system.extraSystemBuilderCmds = ''
    cp ${bootScript} $out/boot
    cp ${enterScript} $out/enter
  '';
  boot.isContainer = true;
  networking.dhcpcd.enable = false;
  networking.firewall.enable = false;
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
    cp -v /nix/var/nix/profiles/system/boot /boot
    cp -v /nix/var/nix/profiles/system/enter /enter
    ln -sv ./nix/var/nix/profiles/system/init init
    mkdir -pv /etc/nixos/
    if [ ! -f /etc/nixos/configuration.nix ]; then
      cp ${./configuration.nix} /etc/nixos/configuration.nix
    fi
    if [ ! -f /etc/nixos/container-helper.nix ]; then
      cp ${./container-helper.nix} /etc/nixos/container-helper.nix
    fi

    # Reread host resolv.conf from backup
    resolvconf -m 10000 -a host < /etc/resolv.conf.bak
  '';
}
