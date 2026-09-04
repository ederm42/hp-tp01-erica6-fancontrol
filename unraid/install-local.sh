#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC="$ROOT/unraid/hp-tp01-erica6-fancontrol.plg"
TMP=/tmp/hp-tp01-erica6-fancontrol.plg

if [[ ! -f "$SRC" ]]; then
    echo "Missing $SRC" >&2
    exit 1
fi

cp "$SRC" "$TMP"
plugin install "$TMP" forced

echo
echo "Installed from $TMP"
echo "Open Settings > HP TP01 Erica6 Fan Control"
