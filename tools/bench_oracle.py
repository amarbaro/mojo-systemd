"""Same work as tests/bench.mojo in Python: open, sendto, close one AF_UNIX datagram socket per notify, N times."""
import os, socket, time
N, addr = 100000, os.environ["NOTIFY_SOCKET"]
ok = 0; t0 = time.perf_counter_ns()
for i in range(N):
    with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as s:
        s.sendto(f"STATUS={i}".encode(), addr); ok += 1
print("notify_us", (time.perf_counter_ns() - t0) / 1000 / N, "sent", ok)
