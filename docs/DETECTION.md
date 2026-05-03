# Detection

Clamshell is intentionally boring.

It does not call a server. It does not use private APIs. It watches local state every eight seconds.

## Codex App

Clamshell treats the Codex App as active when either condition is true:

- `/Applications/Codex.app/Contents/Resources/codex app-server` has non-background child work.
- A Codex session JSONL under `~/.codex/sessions` or `~/.codex/archived_sessions` changed inside the settle window.

The default settle window is 90 seconds. This avoids sleeping the Mac during the quiet gap after a model response or tool call.

Ignored Codex App child helpers:

- `node_repl`
- `SkyComputerUseClient mcp`
- `@upstash/context7-mcp`
- `chrome_crashpad_handler`
- `Codex Helper`

## Codex CLI

Clamshell treats Codex CLI as active when a local process command contains `codex` and is not an app-server process.

## Claude / Cloud Code CLI

Clamshell treats Claude / Cloud Code as active when a local process command points at a Claude Code native binary or contains `claude-code` or `cloud-code`.

## Sleep Control

Normal macOS idle-sleep assertions are not enough for a closed MacBook lid. Clamshell uses both:

- `IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleSystemSleep)`
- `/usr/bin/pmset -a disablesleep 1` through the tiny installed helper

When jobs settle, Clamshell runs:

- `/usr/bin/pmset -a disablesleep 0`
- `/usr/bin/pmset sleepnow`

That is the whole privileged surface.
