{ ... }:

{
  boot.isContainer = true;
  networking.hostName = "guest";
  networking.dhcpcd.enable = false;
    boot.postBootCommands =
      ''
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
      '';
}
