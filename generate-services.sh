services=$(
  systemctl list-units --no-legend --no-pager --type service --all |
    sed 's/^●//' |
    awk '{print $1}' |
    sed 's/\.service$//'
)

tmpfile=$(mktemp)
echo "[" >"$tmpfile"
for service in $services; do
  # if service starts with `notify-failure@`, check using grep
  if echo "$service" | grep -q '^notify-failure@'; then
    continue
  fi
  exec=$(systemctl show "$service" --property ExecStart --property ExecStop --value)
  if [ -z "$exec" ]; then
    continue
  fi
  success_action=$(systemctl show "$service" --property SuccessAction --value)
  if [ "$success_action" == "none" ]; then
    continue
  fi
  echo "  \"$service\"" >>"$tmpfile"
done
echo "]" >>"$tmpfile"
cat "$tmpfile"
