{ config, lib, ... }:

{
  options = {
    kexec.autoJustdoit = lib.mkOption {
      default = true;
      description = "automatically run justdoit on boot";
      type = lib.types.bool;
    };
  };
  config = lib.mkIf config.kexec.autoJustdoit {
    systemd.units.justdoit = {
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.justdoit = {
      script = "${config.system.build.justdoit}/justdoit";
    };
  };
}
