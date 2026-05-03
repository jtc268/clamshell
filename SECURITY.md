# Security

Clamshell has no networking, telemetry, analytics, update checker, or cloud account.

The privileged helper is a small C wrapper around four allowlisted commands:

- `pmset -a disablesleep 1`
- `pmset -a disablesleep 0`
- `pmset sleepnow`
- `pmset -g`

Install builds the helper from source, installs it at `/usr/local/libexec/clamshell-helper`, and sets it root-owned with mode `4755` so the unprivileged menu bar app can restore sleep after the lid is closed.

The recommended one-line install clones the repository first, then runs `./install.sh` from the checkout. The installer does not fetch and execute a remote shell script.

To remove it:

```bash
[ ! -e /usr/local/libexec/clamshell-helper ] || sudo /bin/rm /usr/local/libexec/clamshell-helper
```

Then drag `/Applications/Clamshell.app` to the Trash.
