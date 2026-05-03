#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_PATH="$("$ROOT/scripts/package_app.sh")"
clang -O2 -Wall -Wextra "$ROOT/helper/clamshell-helper.c" -o "$ROOT/dist/clamshell-helper"

echo "Built: $APP_PATH"
echo "Built: $ROOT/dist/clamshell-helper"

set +e
"$APP_PATH/Contents/MacOS/Clamshell" --probe
probe_status=$?
set -e

if [[ "$probe_status" -ne 0 && "$probe_status" -ne 2 ]]; then
  echo "Probe failed with unexpected status $probe_status" >&2
  exit "$probe_status"
fi

echo "Probe completed with status $probe_status"
