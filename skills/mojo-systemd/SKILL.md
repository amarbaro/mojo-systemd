---
name: mojo-systemd
description: "sd_notify from Mojo: ready, status, watchdog, stopping, watchdog_usec. Use when a Mojo service runs under systemd as Type=notify or with WatchdogSec."
---

# mojo-systemd

`mojo run -I <repo>/src app.mojo`. Calls return False outside systemd, so no guard is needed.

    from systemd import ready, status, watchdog, watchdog_usec
    _ = ready("serving")
    # loop: ping every watchdog_usec()/2 microseconds
    _ = watchdog()

Unit: `Type=notify`, optional `WatchdogSec=N`. Check: `scripts/check.sh` ends `PASS all`.
