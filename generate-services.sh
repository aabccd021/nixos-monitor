filename=${1:-}

if [ -z "$filename" ]; then
  filename="$(hostname)-services.nix"
fi

services=$(
  systemctl list-units --no-legend --no-pager --type service --all |
    sed 's/^●//' |
    awk '{print $1}'
)
echo "[" >"$filename"
for service in $services; do
  echo "  \"$service\"" >>"$filename"
done
echo "]" >>"$filename"
