services=$(
  systemctl list-units --no-legend --no-pager --type service --all |
    sed 's/^●//' |
    awk '{print $1}' |
    sed 's/\.service$//'
)
echo "["
for service in $services; do
  echo "  \"$service\""
done
echo "]"
