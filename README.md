# mojo-systemd

<!-- badges -->
[![ci](https://github.com/amarbaro/mojo-systemd/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/amarbaro/mojo-systemd/actions/workflows/ci.yml) [![latest release](https://img.shields.io/github/v/release/amarbaro/mojo-systemd)](https://github.com/amarbaro/mojo-systemd/releases/latest) [![license](https://img.shields.io/github/license/amarbaro/mojo-systemd)](https://github.com/amarbaro/mojo-systemd/blob/main/LICENSE)
<!-- /badges -->

<!-- install -->
Install: `pixi add mojo-systemd` once published. For now: `git clone https://github.com/amarbaro/mojo-systemd`, then `mojo run -I mojo-systemd/src app.mojo`.

```mojo
from systemd import ready, status, watchdog, watchdog_usec


def main() raises:
    # Under a Type=notify unit these reach systemd; without NOTIFY_SOCKET each returns False and nothing is sent.
    print(ready("serving"), status("3 jobs queued"), watchdog(), watchdog_usec())
```
<!-- /install -->

Tell systemd from Mojo that a service is ready, what it is doing, and that it is still alive
(the sd_notify protocol). Libc only, no libsystemd. The datagrams are checked byte for
byte against a Python sender, and a real `Type=notify` unit with `WatchdogSec` proves the
watchdog stays quiet while pings flow and kills the service when they stop.

Requires Mojo 1.2 on Linux.

## What you get

- `notify(state)`: send any sd_notify state string, for example `"READY=1\nMAINPID=42"`.
- `ready(msg="")`, `status(msg)`, `watchdog()`, `stopping()`, `reloading()` (with the
  `MONOTONIC_USEC` systemd 253+ expects).
- `watchdog_usec()`: the interval from `$WATCHDOG_USEC`, 0 when off or when `$WATCHDOG_PID`
  names another process.
- Every call returns `False` outside systemd (`$NOTIFY_SOCKET` unset), so the same binary runs
  from a shell. A set but unusable socket raises `systemd: ...`.
- Path and abstract (`@name`) sockets.

API: [docs/api.md](docs/api.md). Design: [docs/design.md](docs/design.md).

## Checks

| Script | What |
|---|---|
| `scripts/check.sh` | 8 calls under 7 socket/env setups, datagrams identical to `tools/oracle.py`; then a real user unit, `Type=notify`, `WatchdogSec=1`: pinging stays active, silent gets killed with `Result=watchdog` |
| `scripts/selfcheck.sh` | 4 mutants (abstract socket, WATCHDOG_PID, dropped byte, no pings) all rejected |
| `scripts/ci.sh` | install and gate, same on GitHub and a local VM; without a user service manager the unit part prints `SKIP` and the last line says so |

## License

Apache-2.0.
