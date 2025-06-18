{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.systemd-sendmail;
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
      ++ (builtins.map (serviceName: {
        services.${serviceName}.unitConfig.OnFailure = [ "notify-failure@${serviceName}.service" ];
      }) cfg.services)

    )
  );
}
