filename=${1:-}

if [ -z "$filename" ]; then
  filename="$(hostname)-services.nix"
fi

# remove .service suffix from service names
services=$(
  systemctl list-units --no-legend --no-pager --type service --all |
    sed 's/^●//' |
    awk '{print $1}' |
    sed 's/\.service$//'
)
echo "[" >"$filename"
for service in $services; do
  echo "Processing service: $service"
  if echo "$service" | grep -q '^notify-failure@'; then
    continue
  fi
  echo "  \"$service\"" >>"$filename"
done
echo "]" >>"$filename"
