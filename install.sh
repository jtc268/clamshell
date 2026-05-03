#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${CLAMSHELL_REPO_URL:-https://github.com/jtc268/clamshell.git}"
WORKDIR="${TMPDIR:-/tmp}/clamshell-install"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need git
need swift
need clang
need sudo

if [[ -f "Package.swift" && -d "Sources/Clamshell" ]]; then
  ROOT="$(pwd)"
else
  rm -rf "$WORKDIR"
  git clone --depth 1 "$REPO_URL" "$WORKDIR"
  ROOT="$WORKDIR"
fi

cd "$ROOT"

APP_PATH="$("$ROOT/scripts/package_app.sh")"

echo "Installing Clamshell.app to /Applications"
rm -rf /tmp/Clamshell.app
cp -R "$APP_PATH" /tmp/Clamshell.app
sudo rm -rf /Applications/Clamshell.app
sudo cp -R /tmp/Clamshell.app /Applications/Clamshell.app

echo "Installing audited pmset helper to /usr/local/libexec/clamshell-helper"
sudo mkdir -p /usr/local/libexec
sudo install -o root -g wheel -m 4755 "$ROOT/dist/clamshell-helper" /usr/local/libexec/clamshell-helper

echo "Opening Clamshell"
open /Applications/Clamshell.app
