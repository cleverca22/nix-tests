how to install nixos from legacy booting

first, boot via legacy, and install with the following options

```nix
boot.loader.grub.efiSupport = true;
boot.loader.grub.efiInstallAsRemovable = true;
boot.loader.grub.device = "nodev";
```

then boot that via EFI, and change the config

```nix
boot.loader.grub.efiInstallAsRemovable = false;
boot.loader.efi.canTouchEfiVariables = true;
```

then ``NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild switch`` and confirm nixos is listed in ``efibootmgr``, then you can safely delete /boot/EFI/BOOT/BOOTX64.EFI
