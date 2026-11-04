#!/usr/bin/env bash
# Proves the gate rejects wrong code: each mutant is applied to a copy of the tree and
# scripts/check.sh must FAIL on it. Then the oracle as its own stand-in must pass the oracle part, and a host
# without a user service manager must still run tests/api.mojo and report SKIP, not PASS.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
mutants=(
  "src/systemd/notify.mojo|        a[2] = 0|        pass|abstract socket sent as a path"
  "src/systemd/notify.mojo|Int(pid) != Int|Int(pid) == Int|WATCHDOG_PID check inverted"
  "src/systemd/notify.mojo|state.byte_length(), Int32(0x4000)|state.byte_length() - 1, Int32(0x4000)|last byte dropped"
  "examples/service.mojo|        _ = watchdog()|        pass|service never pings"
)
for m in "${mutants[@]}"; do
  IFS='|' read -r file from to why <<< "$m"
  d=$ROOT/.work/mutant; rm -rf "$d"; mkdir -p "$d"
  cp -r src tests tools scripts examples "$d"; ln -s "$ROOT/.venv" "$d/.venv"
  python3 -I -c 'import sys; p,a,b=sys.argv[1:]; s=open(p).read(); assert a in s, "mutant does not apply: "+a; open(p,"w").write(s.replace(a,b,1))' "$d/$file" "$from" "$to" \
    || { echo "FAIL selfcheck: mutant does not apply ($why)"; exit 1; }
  if "$d/scripts/check.sh" > "$d.log" 2>&1; then echo "FAIL selfcheck: gate passed a mutant ($why)"; exit 1; fi
  echo "selfcheck: rejected ($why): $(grep -m1 FAIL "$d.log")"
done
CASES="python3 -I tools/oracle.py" scripts/check.sh > .work/oracle-self.log 2>&1 || { echo "FAIL selfcheck: oracle fails its own gate"; tail -3 .work/oracle-self.log; exit 1; }
# no user service manager (a fake systemctl that reports offline): api.mojo runs, the unit test is skipped, no PASS line
mkdir -p .work/nosysd; printf '#!/bin/sh\necho offline\nexit 1\n' > .work/nosysd/systemctl; chmod +x .work/nosysd/systemctl
PATH=$ROOT/.work/nosysd:$PATH scripts/check.sh > .work/nosysd.log 2>&1 || { echo "FAIL selfcheck: a host without systemd fails the gate"; tail -3 .work/nosysd.log; exit 1; }
grep -q "^api: ok" .work/nosysd.log || { echo "FAIL selfcheck: no user manager: tests/api.mojo did not run"; exit 1; }
grep -q "^SKIP" .work/nosysd.log || { echo "FAIL selfcheck: no user manager: no SKIP status"; exit 1; }
! grep -q "^PASS" .work/nosysd.log || { echo "FAIL selfcheck: no user manager: a skipped gate printed PASS"; exit 1; }
echo "PASS selfcheck"
