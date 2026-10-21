#!/usr/bin/env bash
# The gate. tests/calls.txt runs through $CASES (default: tests/cases.mojo built to .work/cases)
# and through tools/oracle.py under each socket/env setup; the receiver's transcripts must be
# identical. Then, with a user systemd manager, a real Type=notify unit with WatchdogSec.
# CASES="python3 -I tools/oracle.py" proves the gate with the oracle as its own stand-in.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .work
M=.venv/bin/mojo
CASES=${CASES:-.work/cases}
if [[ $CASES == .work/cases ]]; then
  $M build -I src tests/cases.mojo -o .work/cases 2>.work/build.err || { echo "FAIL build: tests/cases.mojo"; cat .work/build.err; exit 1; }
fi
S=$PWD/.work/notify.sock
setups=("$S|" "@mojo-systemd-$$|" "unset|" "bad|" "$S|WATCHDOG_USEC=500000" "$S|WATCHDOG_USEC=500000,WATCHDOG_PID=1" "$S|WATCHDOG_USEC=x")
for i in "${!setups[@]}"; do
  IFS='|' read -r addr env <<< "${setups[$i]}"
  for who in impl oracle; do
    rm -f "$S"
    if [[ $who == impl ]]; then cmd=($CASES); else cmd=(python3 -I tools/oracle.py); fi
    python3 -I tools/recv_oracle.py "$addr" "$env" "${cmd[@]}" tests/calls.txt > .work/$i.$who 2>.work/err \
      || { echo "FAIL run: setup $i ($who)"; cat .work/err; exit 1; }
  done
  diff .work/$i.impl .work/$i.oracle > .work/oracle.diff || { echo "FAIL oracle: setup $i ($addr $env)"; cat .work/oracle.diff; exit 1; }
  echo "oracle: setup $i ($addr ${env:-no env}) identical, $(grep -c dgram .work/$i.impl) datagrams"
done
grep -q "usec 500000" .work/4.impl && grep -q "usec 0" .work/5.impl || { echo "FAIL oracle: watchdog_usec values"; exit 1; }
if ! systemctl --user is-system-running >/dev/null 2>&1 && [[ $(systemctl --user is-system-running 2>/dev/null) != degraded ]]; then
  echo "SKIP systemd: no user service manager here"; echo "PASS oracle (systemd unit test skipped)"; exit 0
fi
$M build -I src examples/service.mojo -o .work/service 2>.work/build.err || { echo "FAIL build: examples/service.mojo"; cat .work/build.err; exit 1; }
unit() {  # unit NAME PINGS WAIT_S: run a Type=notify unit with a 1 s watchdog, print its result after WAIT_S
  systemctl --user reset-failed "$1" 2>/dev/null || true
  systemd-run --user --quiet --unit="$1" -p Type=notify -p WatchdogSec=1 -p NotifyAccess=main "$PWD/.work/service" "$2" \
    || { echo "FAIL systemd: $1 did not reach READY"; exit 1; }
  sleep "$3"
  systemctl --user show -p ActiveState,Result,StatusText --value "$1" | paste -sd' '
  systemctl --user stop "$1" 2>/dev/null || true
  systemctl --user reset-failed "$1" 2>/dev/null || true
}
alive=$(unit mojo-systemd-alive-$$ 0 3)
[[ " $alive " == *" active "* && $alive == *"ping "* && " $alive " == *" success "* ]] || { echo "FAIL systemd: pinging unit not alive and pinging: $alive"; exit 1; }
echo "systemd: pinging unit alive after 3 s ($alive)"
dead=$(unit mojo-systemd-silent-$$ 2 4)
[[ $dead == *watchdog* ]] || { echo "FAIL systemd: silent unit not killed by the watchdog: $dead"; exit 1; }
echo "systemd: silent unit killed by the watchdog ($dead)"
$M run -I src tests/api.mojo || { echo "FAIL api: tests/api.mojo"; exit 1; }
echo "PASS all"
