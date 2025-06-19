services=$(
  systemctl list-units --no-legend --no-pager --type timer --all |
    sed 's/^●//' |
    awk '{print $1}' |
    sed 's/\.timer$//'
)

tmpfile=$(mktemp)
echo "[" >"$tmpfile"
for service in $services; do
  if echo "$service" | grep -q '@'; then
    continue
  fi
  exec=$(systemctl show "$service" --property ExecStart --property ExecStop --value)
  success_action=$(systemctl show "$service" --property SuccessAction --value)
  if [ -z "$exec" ] && [ "$success_action" == "none" ]; then
    continue
  fi
  echo "  \"$service\"" >>"$tmpfile"
done
echo "]" >>"$tmpfile"
cat "$tmpfile"
