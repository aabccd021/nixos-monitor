{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.services.journald-sendmail;
in
{

  options.services.journald-sendmail = {
    enable = lib.mkEnableOption "Journald Sendmail Service";
    sources = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            startAt = lib.mkOption {
              type = lib.types.str;
              default = "*:0/5";
            };
            args = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
      default = { };
      description = "Journald sources to send logs from.";
    };
  };

  config.systemd = lib.mkIf cfg.enable (
    lib.mkMerge (
      lib.mapAttrsToList (sourceName: sourceCfg: {
        services."journald-sendmail-${sourceName}" = {
          serviceConfig.Type = "oneshot";
          environment.SOURCE_NAME = sourceName;
          startAt = sourceCfg.startAt;
          path = [
            "/run/current-system/sw/"
            pkgs.sendmail
          ];
          enableStrictShellChecks = true;
          script = ''
            cursor_file="/var/lib/journald-sendmail/cursors/$SOURCE_NAME"
            mkdir -p "$(dirname "$cursor_file")"
            journalctl --quiet --cursor-file="$cursor_file" ${lib.escapeShellArgs sourceCfg.args}) \
              | sendmail
          '';
        };
      }) cfg.sources
    )

  );
}
