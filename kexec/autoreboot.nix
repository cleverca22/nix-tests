{ config, lib, ... }:

{
  options = {
    kexec.autoReboot = lib.mkOption {
      default = true;
      description = "auto-reboot at the end of the hour";
      type = lib.types.bool;
    };
  };
  config = lib.mkIf config.kexec.autoReboot {
    systemd.timers.autoreboot = {
      partOf = [ "autoreboot.service" ];
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = "hourly";
    };
    systemd.services.autoreboot = {
      script = "shutdown -r +5";
    };
  };
}
