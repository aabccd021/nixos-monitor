services=$(
  systemctl list-units --no-legend --no-pager --type service --all |
    sed 's/^●//' |
    awk '{print $1}' |
    sed 's/\.service$//'
)
echo "["
for service in $services; do
  details=$(systemctl show "$service" --property ExecStart --property ExecStop --property SuccessAction)
  if [ -n "$details" ]; then
    echo "  \"$service\""
  fi
done
echo "]"
