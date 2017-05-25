let
  pkgs = import <nixpkgs> { config = {}; };
  callPackage = pkgs.newScope self;
  self = {
    qemu_test1 = let
        config = (import <nixpkgs/nixos> { configuration = ./configuration.nix; }).config;
        image = config.system.build.image;
      in pkgs.writeScriptBin "qemu_test1" ''
      #!${pkgs.stdenv.shell}
      export PATH=${pkgs.qemu_kvm}/bin/:$PATH

      if ! test -e dummy_root.qcow2; then
        qemu-img create -f qcow2 dummy_root.qcow2 20G
      fi

      qemu-kvm -kernel ${image}/kernel -initrd ${image}/initrd -m 2048 -append "init=${builtins.unsafeDiscardStringContext config.system.build.toplevel}/init ${toString config.boot.kernelParams}" -monitor stdio -drive index=0,id=drive1,file=dummy_root.qcow2,cache=writeback,werror=report,if=virtio
    '';
    qemu_test2 = pkgs.writeScriptBin "qemu_test2" ''
      #!${pkgs.stdenv.shell}
      export PATH=${pkgs.qemu_kvm}/bin/:$PATH 

      qemu-kvm -monitor stdio -drive index=0,id=drive1,file=dummy_root.qcow2,cache=writeback,werror=report,if=virtio
    '';
    qemu_test = pkgs.buildEnv {
      name = "qemu_test";
      paths = with self; [ qemu_test1 qemu_test2 ];
    };
  };
in self
