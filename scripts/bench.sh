#!/usr/bin/env bash
# tests/bench.mojo vs tools/bench_oracle.py: 100k sd_notify datagrams each to one local receiver, 3 alternating rounds.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .work; PY=python3; [ -x .venv/bin/python ] && PY=.venv/bin/python
.venv/bin/mojo build -O3 -I src tests/bench.mojo -o .work/bench 2>.work/build.err || { echo "FAIL build: tests/bench.mojo"; cat .work/build.err; exit 1; }
export NOTIFY_SOCKET=$PWD/.work/notify.sock; rm -f "$NOTIFY_SOCKET"
$PY -I tools/bench_sink.py "$NOTIFY_SOCKET" > .work/sink.out & sink=$!; trap 'kill $sink 2>/dev/null || true' EXIT
for _ in $(seq 50); do grep -q READY .work/sink.out 2>/dev/null && break; sleep 0.1; done
grep -q READY .work/sink.out || { echo "FAIL setup: receiver did not start"; exit 1; }
for i in 1 2 3; do
  m=$(.work/bench) || { echo "FAIL run: mojo"; exit 1; }; echo "mojo    $m"
  p=$($PY -I tools/bench_oracle.py) || { echo "FAIL run: python"; exit 1; }; echo "python  $p"
done
