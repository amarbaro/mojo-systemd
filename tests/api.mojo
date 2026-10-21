# Outside systemd every call reports False and nothing raises.
from std.os import unsetenv
from systemd import ready, status, watchdog, stopping, watchdog_usec


def main() raises:
    _ = unsetenv("NOTIFY_SOCKET")
    _ = unsetenv("WATCHDOG_USEC")
    if ready() or status("x") or watchdog() or stopping() or watchdog_usec() != 0:
        raise Error("api: a call claimed success without NOTIFY_SOCKET")
    print("api: ok")
