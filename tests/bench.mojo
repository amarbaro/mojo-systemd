# notify() throughput: N datagrams to $NOTIFY_SOCKET (scripts/bench.sh starts a receiver). Same work as tools/bench_oracle.py.
from std.time import perf_counter_ns
from systemd import notify


def main() raises:
    comptime N = 100000
    var ok = 0
    var t0 = perf_counter_ns()
    for i in range(N):
        if notify("STATUS=" + String(i)):
            ok += 1
    var t1 = perf_counter_ns()
    print("notify_us", Float64(t1 - t0) / 1000.0 / Float64(N), "sent", ok)
