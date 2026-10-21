"""Oracle sender: sd_notify(3) as systemd documents it, same scenario format as tests/cases.mojo."""
import os, socket, sys, time

def notify(state):
    p = os.environ.get("NOTIFY_SOCKET", "")
    if not p:
        return "unset"
    if p[0] not in "/@" or len(p) >= 108:
        return "error"
    addr = "\0" + p[1:] if p[0] == "@" else p
    s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    try:
        s.sendto(state.encode(), addr)
        return "sent"
    except OSError:
        return "error"
    finally:
        s.close()

def usec():
    pid, us = os.environ.get("WATCHDOG_PID", ""), os.environ.get("WATCHDOG_USEC", "")
    try:
        if pid and int(pid) != os.getpid():
            return 0
        return int(us) if us else 0
    except ValueError:
        return 0

for line in open(sys.argv[1]).read().splitlines():
    op, _, arg = line.partition(" ")
    arg = arg.replace("\\n", "\n")
    if op == "usec":
        print("usec", usec()); continue
    state = {"ready": "READY=1" + ("\nSTATUS=" + arg if arg else ""), "status": "STATUS=" + arg,
             "watchdog": "WATCHDOG=1", "stopping": "STOPPING=1",
             "reloading": "RELOADING=1\nMONOTONIC_USEC=%d" % (time.clock_gettime_ns(time.CLOCK_MONOTONIC) // 1000)}.get(op, arg)
    print(op, notify(state))
