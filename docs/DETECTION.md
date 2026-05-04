# Detection

Clamshell is intentionally boring.

It does not call a server. It does not use private APIs. It watches local state every eight seconds.

## Codex App

Clamshell treats the Codex App as active when the Codex app-server is running and a Codex session JSONL under `~/.codex/sessions` or `~/.codex/archived_sessions` changed inside the settle window.

The default settle window is five minutes. This avoids sleeping the Mac during quiet gaps between model responses or tool calls.

Codex app-server children do not make the app active by themselves because idle Codex windows can keep helper processes alive.

## Codex CLI

Clamshell treats Codex CLI as active when a local `codex` process has child tool work, or when a non-Codex-App session update happens while a `codex` process is present.

It ignores Codex Terminal wrapper processes so an open Codex UI does not appear as a separate active CLI.

## Claude Code CLI

Clamshell treats Claude Code CLI as active when a local process command is `claude`, points at `@anthropic-ai/claude-code`, contains `claude-code`, or points at a compatible native Claude CLI binary.

This is a process-level optional hook. Codex App remains the primary target.

## Sleep Control

Normal macOS idle-sleep assertions are not enough for a closed MacBook lid. Clamshell uses both:

- `IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep)`
- `/usr/bin/pmset -a disablesleep 1` through the tiny installed helper

When jobs settle, Clamshell runs:

- `/usr/bin/pmset -a disablesleep 0`
- `/usr/bin/pmset sleepnow`

That is the whole privileged surface.
