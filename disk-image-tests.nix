# build with one of:
# * nix-build '<nixpkgs/nixos>' -I nixos-config=./disk-image-tests.nix -A config.system.build.ext4
# * nix-build '<nixpkgs/nixos>' -I nixos-config=./disk-image-tests.nix -A config.system.build.tarball

{ config, pkgs, ... }:

{
  boot.loader.grub.enable = false;
  fileSystems = {
    "/" = {
      label = "NIXOS_ROOT";
    };
  };
  boot.postBootCommands = ''
    if [ -f /nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration && rm /nix-path-registration
    fi
    ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

    # resize the ext4 image to occupy the full partition
    rootPart=$(readlink -f /dev/disk/by-label/NIXOS_ROOT)
    ${pkgs.e2fsprogs}/bin/resize2fs $rootPart
  '';
  system.activationScripts.installInitScript = ''
    ln -fs $systemConfig/init /bin/init
  '';
  system.build = {
    # a tarball you can unpack to /
    tarball = pkgs.callPackage (pkgs.path + "/nixos/lib/make-system-tarball.nix") {
      storeContents = [ {
        object = "${config.system.build.toplevel}/init";
        symlink = "/bin/init";
      } ];
      contents = [];
    };
    # an FS you can mount to /
    # note, you will need to make a symlink to the right init yourself or use init=/nix/store/foo/init
    ext4 = pkgs.callPackage (pkgs.path + "/nixos/lib/make-ext4-fs.nix") {
      volumeLabel = "NIXOS_ROOT";
      storePaths = [ config.system.build.toplevel ];
    };
  };
}
