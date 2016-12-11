using this nix expression and a copy of nixpkgs from nixos-unstable, you can boot a nixos ramdisk on any server with a linux kernel that has kexec enabled

to use, insert your own ssh public key into the authorizedKeys for root, and then execute as seen in session.md

you are also free to pre-install custom tools into the ramdisk by just adding them to configuration.nix just like you would on a normal nixos system

one simple customization would be ``boot.supportedFilesystems = [ "zfs" ];``

and once you have nixos in a ramdisk, you are free to delete all partitions, and nixos-install like normal
