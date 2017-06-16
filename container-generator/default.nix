let
  eval = import <nixpkgs/nixos> { configuration = ./configuration.nix; };
  pkgs = eval.config._module.args.pkgs;
in rec {
  cfg = { ... }: {
    services.mingetty.autologinUser = "root";
    virtualisation.memorySize = 2048;
    services.xserver = {
      enable = true;
      displayManager.slim = {
        enable = true;
        autoLogin = true;
        defaultUser = "root";
      };
      desktopManager.xfce.enable = true;
    };
    networking.hostName = "host";
    environment.systemPackages = [ (
      pkgs.writeScriptBin "doit" ''
        cd /root
        mkdir -p t
        mount -t tmpfs none /root/t -o size=2048m
        cd t
        tar -xf ${eval.config.system.build.tarball}/tarball/nixos-system-x86_64-linux.tar.xz
      ''
    ) ];
  };
  test-guest = (import <nixpkgs/nixos> { configuration = cfg; }).vm;
}
