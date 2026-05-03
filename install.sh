#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need swift
need clang
need sudo
need ditto
need open

if [[ ! -f "$ROOT/Package.swift" || ! -d "$ROOT/Sources/Clamshell" ]]; then
  echo "Run install.sh from a Clamshell source checkout." >&2
  exit 1
fi

cd "$ROOT"

APP_PATH="$("$ROOT/scripts/package_app.sh")"

echo "Installing Clamshell.app to /Applications"
sudo /usr/bin/ditto "$APP_PATH" /Applications/Clamshell.app

echo "Installing audited pmset helper to /usr/local/libexec/clamshell-helper"
sudo mkdir -p /usr/local/libexec
sudo install -o root -g wheel -m 4755 "$ROOT/dist/clamshell-helper" /usr/local/libexec/clamshell-helper

echo "Opening Clamshell"
open /Applications/Clamshell.app
