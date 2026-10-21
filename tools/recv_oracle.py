"""Receiver: binds NOTIFY_SOCKET (a path, or @name for abstract), runs the sender command with the
given extra env, prints the sender's stdout then every datagram, MONOTONIC_USEC normalised."""
import os, re, socket, subprocess, sys
addr, env_kv, cmd = sys.argv[1], sys.argv[2], sys.argv[3:]
s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
if addr not in ("unset", "bad"):
    s.bind("\0" + addr[1:] if addr[0] == "@" else addr)
env = dict(os.environ)
env.pop("NOTIFY_SOCKET", None); env.pop("WATCHDOG_USEC", None); env.pop("WATCHDOG_PID", None)
if addr == "bad":
    env["NOTIFY_SOCKET"] = "relative/path"
elif addr != "unset":
    env["NOTIFY_SOCKET"] = addr
for kv in filter(None, env_kv.split(",")):
    k, v = kv.split("=", 1)
    env[k] = v
out = subprocess.run(cmd, env=env, capture_output=True, text=True, check=True).stdout
sys.stdout.write(out)
s.setblocking(False)
while True:
    try:
        d = s.recv(65536).decode()
    except BlockingIOError:
        break
    print("dgram", repr(re.sub(r"MONOTONIC_USEC=\d+", "MONOTONIC_USEC=N", d)))
