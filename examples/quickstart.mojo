from systemd import ready, status, watchdog, watchdog_usec


def main() raises:
    # Under a Type=notify unit these reach systemd; without NOTIFY_SOCKET each returns False and nothing is sent.
    print(ready("serving"), status("3 jobs queued"), watchdog(), watchdog_usec())
