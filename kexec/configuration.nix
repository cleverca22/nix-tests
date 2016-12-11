# new cmd: nix-build '<nixpkgs/nixos>' -A config.system.build.kexec_tarball -I nixos-config=./configuration.nix -Q -j 4
# old cmd: nix-build -I nixpkgs=/home/clever/apps/nixpkgs/ '<nixpkgs/nixos>' -A config.system.build.kexec_script -I nixos-config=/home/clever/apps/nixpkgs/configuration.nix

{ lib, pkgs, config, ... }:

with lib;

let
  image = pkgs.runCommand "image" { buildInputs = [ pkgs.nukeReferences ]; } ''
    mkdir $out
    cp ${config.system.build.kernel}/bzImage $out/kernel
    cp ${config.system.build.netbootRamdisk}/initrd $out/initrd
    nuke-refs $out/kernel
  '';
in {
  imports = [ <nixpkgs/nixos/modules/installer/netboot/netboot-minimal.nix> ];
  system.build.kexec_script = pkgs.writeTextFile {
    executable = true;
    name = "kexec-nixos";
    text = ''
      #!${pkgs.stdenv.shell}
      export PATH=${pkgs.kexectoolsFixed}/bin:${pkgs.cpio}/bin:$PATH
      set -x
      cd $(mktemp -d)
      pwd
      mkdir initrd
      pushd initrd
      cat /ssh_pubkey >> authorized_keys
      find -type f | cpio -o -H newc | gzip -9 > ../extra.gz
      popd
      cat ${image}/initrd extra.gz > final.gz

      kexec -l ${image}/kernel --initrd=final.gz --append="init=${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init ${toString config.boot.kernelParams}"
      sync
      echo "executing kernel, filesystems will be improperly umounted"
      kexec -e
    '';
  };
  boot.initrd.postMountCommands = ''
    mkdir -p /mnt-root/root/.ssh/
    cp /authorized_keys /mnt-root/root/.ssh/
  '';
  system.build.kexec_tarball = pkgs.callPackage <nixpkgs/nixos/lib/make-system-tarball.nix> {
    storeContents = [
      { object = config.system.build.kexec_script; symlink = "/kexec_nixos"; }
    ];
    contents = [];
  };
  boot.loader.grub.enable = false;
  boot.kernelParams = [ "console=ttyS0,115200" ];
  systemd.services.sshd.wantedBy = mkForce [ "multi-user.target" ];
  networking.hostName = "kexec";
  # example way to embed an ssh pubkey into the tar
  # users.users.root.openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC34wZQFEOGkA5b0Z6maE3aKy/ix1MiK1D0Qmg4E9skAA57yKtWYzjA23r5OCF4Nhlj1CuYd6P1sEI/fMnxf+KkqqgW3ZoZ0+pQu4Bd8Ymi3OkkQX9kiq2coD3AFI6JytC6uBi6FaZQT5fG59DbXhxO5YpZlym8ps1obyCBX0hyKntD18RgHNaNM+jkQOhQ5OoxKsBEobxQOEdjIowl2QeEHb99n45sFr53NFqk3UCz0Y7ZMf1hSFQPuuEC/wExzBBJ1Wl7E1LlNA4p9O3qJUSadGZS4e5nSLqMnbQWv2icQS/7J8IwY0M8r1MsL8mdnlXHUofPlG1r4mtovQ2myzOx clever@nixos" ];
  nixpkgs.config.packageOverrides = pkgs: {
    kexectoolsFixed = pkgs.kexectools.overrideDerivation (old: {
      hardeningDisable = [ "all" ];
    });
  };
}
