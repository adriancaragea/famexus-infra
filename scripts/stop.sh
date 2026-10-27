#!/usr/bin/env bash
# Stops the whole stack.
# Data (MySQL, vendor/, node_modules) stays in the named volumes.
#
# Usage: ./scripts/stop.sh             stop and remove containers, keep data
#        ./scripts/stop.sh --wipe-data also delete every volume (asks first)
#        ./scripts/stop.sh --wipe-data --yes   no prompt, for scripts
set -euo pipefail

wipe=false
yes=false
for arg in "$@"; do
  case "$arg" in
    --wipe-data) wipe=true ;;
    -y|--yes) yes=true ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)" >&2; exit 1 ;;
  esac
done

cd "$(dirname "$0")/.."

compose=(docker compose)

if ! $wipe; then
  "${compose[@]}" down --remove-orphans
  echo
  echo "Famexus is stopped. Data is kept; docker compose up -d starts it again."
  exit 0
fi

echo "This deletes every Famexus volume: all MySQL databases, vendor/ and node_modules."
if ! $yes; then
  if [ ! -t 0 ]; then
    echo "Refusing to wipe data without a terminal; pass --yes to confirm." >&2
    exit 1
  fi
  read -r -p "Type 'wipe' to continue: " answer
  if [ "$answer" != "wipe" ]; then
    echo "Aborted, nothing was changed."
    exit 1
  fi
fi

"${compose[@]}" down --remove-orphans --volumes
echo
echo "Famexus is stopped and its data is gone. Run ./scripts/setup.sh to start fresh."
