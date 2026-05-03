# Clamshell

[![macOS](https://github.com/jtc268/clamshell/actions/workflows/ci.yml/badge.svg)](https://github.com/jtc268/clamshell/actions/workflows/ci.yml)

<p align="center">
  <img src="assets/logo.png" width="128" alt="Clamshell app icon">
</p>

Close your Mac. Let the job finish. Sleep when done.

Clamshell is a tiny macOS menu bar app for developers running long Codex jobs on a MacBook. Flip it on, close the lid, and Clamshell keeps the Mac awake only while watched AI coding jobs are active.

<p align="center">
  <img src="assets/readme/before-stuck-open.png" width="48%" alt="Developer stuck keeping a laptop open while a job runs">
  <img src="assets/readme/after-clamshell.png" width="48%" alt="Developer walking away while Clamshell keeps the job running">
</p>

Stop babysitting the screen. Clamshell watches local Codex activity, holds sleep while work is active, then restores sleep when the last job settles.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jtc268/clamshell/main/install.sh | bash
```

From a checkout:

```bash
./install.sh
```

## Watches

- Codex App
- Codex CLI
- Claude Code CLI

Codex App is on by default. Codex CLI is on by default. Claude Code CLI is optional.

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
