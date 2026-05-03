# Clamshell

[![macOS](https://github.com/YOUR_GITHUB/clamshell/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_GITHUB/clamshell/actions/workflows/ci.yml)

<p align="center">
  <img src="assets/logo.png" width="128" alt="Clamshell app icon">
</p>

Close your Mac. Let the job finish. Sleep when done.

Clamshell is a tiny macOS menu bar app for developers running long Codex jobs on a MacBook. Flip it on, close the lid, and Clamshell keeps the Mac awake only while watched AI coding jobs are active.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB/clamshell/main/install.sh | bash
```

From a checkout:

```bash
./install.sh
```

## Watches

- Codex App
- Codex CLI
- Claude / Cloud Code CLI

Codex App is on by default. Codex CLI is on by default. Claude / Cloud Code is optional.

## Why Trust It

- Native Swift menu bar app.
- No network calls.
- No telemetry.
- No private APIs.
- Local process and session-file detection only.
- Tiny helper with four allowlisted `pmset` commands.

The helper is needed because normal macOS wake assertions do not reliably survive a closed MacBook lid. The helper toggles `pmset disablesleep`, then restores it and runs `pmset sleepnow` after jobs settle.

## Build

```bash
make smoke
```

## Uninstall

```bash
sudo rm -f /usr/local/libexec/clamshell-helper
sudo rm -rf /Applications/Clamshell.app
```

## Details

See [docs/DETECTION.md](docs/DETECTION.md).
