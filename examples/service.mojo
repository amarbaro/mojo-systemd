# A Type=notify service with a watchdog: READY, then a ping every half interval.
# argv[1] = how many pings before it goes silent (systemd then kills it); 0 = forever.
from std.sys import argv
from std.time import sleep
from systemd import ready, status, watchdog, stopping, watchdog_usec


def main() raises:
    var pings = Int(argv()[1]) if len(argv()) > 1 else 0
    var half = Float64(watchdog_usec()) / 2e6
    _ = ready("serving")
    var i = 0
    while pings == 0 or i < pings:
        sleep(half if half > 0 else 1.0)
        _ = watchdog()
        i += 1
        _ = status("ping " + String(i))
    sleep(1e6)  # silent: the watchdog must fire
    _ = stopping()
