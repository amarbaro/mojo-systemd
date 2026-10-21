# mojo-systemd

[![CI](https://github.com/amarbaro/mojo-systemd/actions/workflows/ci.yml/badge.svg)](https://github.com/amarbaro/mojo-systemd/actions/workflows/ci.yml)

Tell systemd from Mojo that a service is ready, what it is doing, and that it is still alive
(the sd_notify protocol). 60 lines, libc only, no libsystemd. The datagrams are checked byte for
byte against a Python sender, and a real `Type=notify` unit with `WatchdogSec` proves the
watchdog stays quiet while pings flow and kills the service when they stop.

```mojo
from systemd import ready, status, watchdog, watchdog_usec
from std.time import sleep

def main() raises:
    _ = ready("serving")                     # Type=notify: start completes here
    var half = Float64(watchdog_usec()) / 2e6
    while True:
        sleep(half if half > 0 else 1.0)
        _ = watchdog()                       # WatchdogSec= keep-alive
        _ = status("3 jobs queued")          # shown by systemctl status
```

## Install

Requires Mojo 1.1 on Linux. Builds on Mojo 1.2 nightly too.

| Way | Command |
|---|---|
| Source path | `mojo run -I path/to/mojo-systemd/src app.mojo` |
| Precompiled | `mojo precompile src/systemd -o systemd.mojoc` |
| Vendor | copy `src/systemd/` into your project |

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
