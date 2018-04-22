let
  pkgs = import <nixpkgs> { config = {}; };
  packages = with pkgs.lib; self: {
    nvme = false;
    uefi = false;
    virtio = true;
    configuration = {};
    configuration1 = {
      imports = [ ./configuration.nix self.configuration ];
    };
    config = (import <nixpkgs/nixos> { configuration = self.configuration1; }).config;
    image = self.config.system.build.image;
    interface = if self.nvme then "none" else (if self.virtio then "virtio" else "scsi");
    qemu_test1 = pkgs.writeScriptBin "qemu_test1" ''
      #!${pkgs.stdenv.shell}
      export PATH=${pkgs.qemu_kvm}/bin/:$PATH

      if ! test -e dummy_root.qcow2; then
        qemu-img create -f qcow2 dummy_root.qcow2 20G
      fi
      if ! test -e my_uefi_vars.bin; then
        cp ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd my_uefi_vars.bin
        chmod +w my_uefi_vars.bin
      fi

      qemu-kvm -kernel ${self.image}/kernel -initrd ${self.image}/initrd -m 2048 \
        -append "init=${builtins.unsafeDiscardStringContext self.config.system.build.toplevel}/init ${toString self.config.boot.kernelParams}" \
        -drive index=0,id=drive1,file=dummy_root.qcow2,cache=writeback,werror=report,if=${self.interface} \
        ${optionalString self.nvme "-device nvme,drive=drive1,serial=1234"} \
        ${optionalString self.uefi "-drive if=pflash,format=raw,readonly,file=${pkgs.OVMF.fd}/FV/OVMF.fd -drive if=pflash,format=raw,file=my_uefi_vars.bin"} \
        -serial mon:stdio
    '';
    qemu_test2 = pkgs.writeScriptBin "qemu_test2" ''
      #!${pkgs.stdenv.shell}
      export PATH=${pkgs.qemu_kvm}/bin/:$PATH 

      qemu-kvm \
        -drive index=0,id=drive1,file=dummy_root.qcow2,cache=writeback,werror=report,if=${self.interface} -m 2048 \
        ${optionalString self.nvme "-device nvme,drive=drive1,serial=1234"} \
        ${optionalString self.uefi "-drive if=pflash,format=raw,readonly,file=${pkgs.OVMF.fd}/FV/OVMF.fd -drive if=pflash,format=raw,file=my_uefi_vars.bin"} \
        -serial mon:stdio
    '';
    qemu_test = pkgs.buildEnv {
      name = "qemu_test";
      paths = with self; [ qemu_test1 qemu_test2 ];
    };
  };
  self = pkgs.lib.makeScope pkgs.newScope packages;
  makeTest = { uefi ? false, nvme ? false, virtio ? false, luks ? false }: let
    pkgs2 = with pkgs.lib; self.overrideScope (super: self: {
      inherit uefi nvme virtio;
      configuration = {
        kexec.justdoit = {
          rootDevice = mkForce (if nvme then "/dev/nvme0n1" else (if virtio then "/dev/vda" else "/dev/sda"));
          nvme = mkForce nvme;
          luksEncrypt = mkForce luks;
          uefi = mkForce uefi;
        };
      };
    });
  in pkgs2.qemu_test;
in {
  legacy_sata = makeTest {};
  uefi_sata = makeTest { uefi = true; };
  nvme = makeTest { uefi = true; nvme = true; };
  luks_legacy = makeTest { luks = true; };
  luks_nvme = makeTest { luks = true; uefi = true; nvme = true; };
}
