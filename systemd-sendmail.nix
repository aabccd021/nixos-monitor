{
  lib,
  config,
  ...
}:
let
  cfg = config.services.systemd-sendmail;

in
{

  options.services.systemd-sendmail = {
    enable = lib.mkEnableOption "systemd Sendmail Service";
    notifyFailure = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of systemd service names to monitor for failures.";
    };
    notifySuccess = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of systemd service names to monitor for successes.";
    };
  };

  config.systemd = lib.mkIf cfg.enable (
    lib.mkMerge (
      [
        {
          services."notify-failure@" = {
            scriptArgs = "%i";
            path = [ "/run/current-system/sw/bin" ];
            script = ''
              echo "Service failed: $1" | sendmail
            '';
          };
          services."notify-success@" = {
            scriptArgs = "%i";
            path = [ "/run/current-system/sw/bin" ];
            script = ''
              echo "Service succeeded: $1" | sendmail
            '';
          };
        }
      ]

      ++ (builtins.map (serviceName: {
        services.${serviceName}.unitConfig.OnFailure = [ "notify-failure@${serviceName}.service" ];
      }) cfg.notifyFailures)

      ++ (builtins.map (serviceName: {
        services.${serviceName}.unitConfig.OnSuccess = [ "notify-success@${serviceName}.service" ];
      }) cfg.notifySuccesses)

    )
  );
}
