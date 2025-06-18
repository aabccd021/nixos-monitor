{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.systemd-sendmail;

  hasServiceConfigField =
    name: field: lib.attrsets.hasAttrByPath [ name "serviceConfig" field ] config.systemd.services;

  shouldEnable =
    name:
    !(lib.strings.hasInfix "@" name)
    && (
      hasServiceConfigField name "ExecStart"
      || hasServiceConfigField name "ExecStop"
      || hasServiceConfigField name "SuccessAction"
    );
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
        (lib.lists.filter shouldEnable)
        (builtins.map (serviceName: {
          services.${serviceName}.unitConfig.OnFailure = [ "notify-failure@${serviceName}.service" ];
        }))
      ])

    )
  );
}
