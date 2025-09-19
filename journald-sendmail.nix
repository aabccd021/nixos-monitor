{
  lib,
  config,
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
            "/run/wrappers/"
          ];
          enableStrictShellChecks = true;
          script = ''
            cursor_file="/var/lib/journald-sendmail/cursors/$SOURCE_NAME"
            mkdir -p "$(dirname "$cursor_file")"

            tmpfile=$(mktemp)
            trap 'rm -f "$tmpfile"' EXIT

            journalctl_exit_code=0
            journalctl --cursor-file="$cursor_file" ${lib.escapeShellArgs sourceCfg.args} > "$tmpfile" || journalctl_exit_code=$?
            content=$(cat "$tmpfile")

            if [ "$content" = "-- No entries --" ] && [ $journalctl_exit_code -eq 1 ]; then
              echo "No new log entries found."
              exit 0
            fi
            if [ "$journalctl_exit_code" -eq 0 ]; then
              echo "New log entries found, sending email."
              sendmail < "$tmpfile"
              exit 0
            fi

            echo "journalctl failed with exit code $journalctl_exit_code with content:"
            cat "$tmpfile"
            exit "$journalctl_exit_code"
          '';
        };
      }) cfg.sources
    )

  );
}
