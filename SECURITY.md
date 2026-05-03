# Security

Clamshell has no networking, telemetry, analytics, update checker, or cloud account.

The privileged helper is a small C wrapper around four allowlisted commands:

- `pmset -a disablesleep 1`
- `pmset -a disablesleep 0`
- `pmset sleepnow`
- `pmset -g`

Install builds the helper from source, installs it at `/usr/local/libexec/clamshell-helper`, and sets it root-owned with mode `4755` so the unprivileged menu bar app can restore sleep after the lid is closed.

To remove it:

```bash
sudo rm -f /usr/local/libexec/clamshell-helper
sudo rm -rf /Applications/Clamshell.app
```
