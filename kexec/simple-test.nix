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
    justdoit = self.config.system.build.justdoit;
    image = self.config.system.build.image;
    interface = if self.nvme then "none" else (if self.virtio then "virtio" else "scsi");
    commonFlags = [
      "-fw_cfg" "opt/com.angeldsis/simple-string,string=foobarbaz"
      "-serial" "mon:stdio"
      "-net" "user,hostfwd=tcp:127.0.0.2:2222-:22" "-net" "nic"
      "-m" "2048"
      "-drive" "index=0,id=drive1,file=dummy_root.qcow2,cache=writeback,werror=report,if=${self.interface}"
    ] ++ optional self.nvme "-device nvme,drive=drive1,serial=1234"
      ++ optional self.uefi "-drive if=pflash,format=raw,readonly,file=${pkgs.OVMF.fd}/FV/OVMF.fd -drive if=pflash,format=raw,file=my_uefi_vars.bin";
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

      qemu-kvm -kernel ${self.image}/kernel -initrd ${self.image}/initrd \
        -append "init=${builtins.unsafeDiscardStringContext self.config.system.build.toplevel}/init ${toString self.config.boot.kernelParams}" \
        ${toString self.commonFlags}
    '';
    qemu_test2 = pkgs.writeScriptBin "qemu_test2" ''
      #!${pkgs.stdenv.shell}
      export PATH=${pkgs.qemu_kvm}/bin/:$PATH

      qemu-kvm ${toString self.commonFlags}
      # -chardev stdio,id=qemu-debug-out -device isa-debugcon,chardev=qemu-debug-out
    '';
    # -debugcon file:debug.log -global isa-debugcon.iobase=0x402 \
    qemu_test = pkgs.buildEnv {
      name = "qemu_test";
      paths = with self; [ qemu_test1 qemu_test2 ];
    };
  };
  self = pkgs.lib.makeScope pkgs.newScope packages;
  makeTest = { uefi ? false, nvme ? false, virtio ? false, luks ? false, bootType ? (if uefi then "vfat" else "ext4")}: let
    pkgs2 = with pkgs.lib; self.overrideScope' (self: super: {
      inherit uefi nvme virtio;
      configuration = {
        kexec.justdoit = {
          rootDevice = mkForce (if nvme then "/dev/nvme0n1" else (if virtio then "/dev/vda" else "/dev/sda"));
          nvme = mkForce nvme;
          luksEncrypt = mkForce luks;
          uefi = mkForce uefi;
          inherit bootType;
        };
      };
    });
  in pkgs2.qemu_test // { justdoit = pkgs2.justdoit; };
in {
  legacy_sata = makeTest {};
  uefi_sata = makeTest { uefi = true; };
  legacy_virtio = makeTest { virtio = true; };
  nvme = makeTest { uefi = true; nvme = true; };
  luks_legacy = makeTest { luks = true; virtio = true; };
  virtio_no_boot = makeTest { virtio = true; bootType = "zfs"; };
  luks_nvme = makeTest { luks = true; uefi = true; nvme = true; };
}
