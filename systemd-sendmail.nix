{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.systemd-sendmail;
  ignoredServices = [
    "auditd"
    "dracut-mount"
    "nfs-kernel-server"
    "nfs-server"
    "plymouth-quit-wait"
    "plymouth-quit"
    "plymouth-start"
    "rpc-statd-notify"
    "smb"
    "sops-install-secrets"
    "syslog"
    "systemd-hwdb-update"
    "systemd-pcrphase-initrd"
    "systemd-quotacheck-root"
    "systemd-quotacheck"
    "systemd-soft-reboot"
    "systemd-sysusers"
    "systemd-udev-load-credentials"
  ];
in
{

  options.services.systemd-sendmail = {
    enable = lib.mkEnableOption "systemd Sendmail Service";
    services = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of systemd service names to monitor for failures.";
    };
  };

  config.systemd = lib.mkIf cfg.enable (
    lib.mkMerge (
      [
        {
          services."notify-failure@" = {
            scriptArgs = "%i";
            path = [ pkgs.sendmail ];
            script = ''
              echo "Service failed: $1" | sendmail
            '';
          };

        }
      ]
      ++ (lib.pipe cfg.services [
        (lib.lists.subtractLists ignoredServices)
        (lib.lists.filter (lib.strings.hasInfix "@"))
        (builtins.map (serviceName: {
          services.${serviceName}.unitConfig.OnFailure = [ "notify-failure@${serviceName}.service" ];
        }))
      ])

    )
  );
}
