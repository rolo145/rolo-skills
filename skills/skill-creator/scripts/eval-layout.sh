#!/usr/bin/env bash
# Build, check and interrogate the workspace layout Mode 4 hands to the official
# aggregator.
#
# This exists because getting the layout wrong fails SILENTLY. aggregate_benchmark
# globs eval-* and requires a run-* level under each config; give it anything else
# and it prints "No eval directories found", then writes a benchmark.json reporting
# Delta +0.00 anyway. A run that measured nothing is indistinguishable from a run
# that measured no difference. Note that the upstream skill's own prose contradicts
# its aggregator here — it says to name eval directories descriptively, which that
# glob then skips — so eval-<N>-<description> is what satisfies both.
#
# Usage:
#   eval-layout.sh init <iteration-dir> <eval-name> [<eval-name>...]
#   eval-layout.sh check <iteration-dir>
#   eval-layout.sh discriminate <iteration-dir>
#
# Configs default to with_skill and baseline; override with CONFIGS="a b".
set -uo pipefail

CONFIGS="${CONFIGS:-with_skill baseline}"
cmd="${1:-}"; shift 2>/dev/null || true
dir="${1:-}"; shift 2>/dev/null || true

if [ -z "$cmd" ] || [ -z "$dir" ]; then
  sed -n '14,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
  exit 64
fi

fail=0
err() { printf '  ERROR  %s\n' "$*"; fail=1; }
ok()  { printf '  ok     %s\n' "$*"; }

case "$cmd" in
init)
  [ "$#" -gt 0 ] || { echo "init needs at least one eval name" >&2; exit 64; }
  i=0
  for name in "$@"; do
    e="$dir/eval-$i-$name"
    for c in $CONFIGS; do mkdir -p "$e/$c/run-1/outputs"; done
    [ -f "$e/eval_metadata.json" ] || cat > "$e/eval_metadata.json" <<JSON
{
  "eval_id": $i,
  "eval_name": "$name",
  "prompt": "TODO — the user task, verbatim",
  "assertions": []
}
JSON
    printf 'eval-%s-%s\n' "$i" "$name"
    i=$((i + 1))
  done
  printf '\nConfigs: %s. Write each run to <config>/run-1/outputs/.\n' "$CONFIGS"
  exit 0
  ;;

check)
  printf 'Checking %s\n' "$dir"
  evals=("$dir"/eval-*)
  [ -e "${evals[0]}" ] || err "no eval-* directories — the aggregator globs eval-*, so a purely descriptive name is skipped without an error"
  stray=0
  for d in "$dir"/*/; do
    b="$(basename "$d")"
    case "$b" in eval-*) ;; *) err "'$b/' will be ignored by the aggregator — rename it eval-<N>-$b"; stray=1 ;; esac
  done
  [ "$stray" = 0 ] && [ -e "${evals[0]}" ] && ok "every directory matches eval-*"

  for e in "$dir"/eval-*/; do
    [ -d "$e" ] || continue
    n="$(basename "$e")"
    [ -f "$e/eval_metadata.json" ] || err "$n: no eval_metadata.json at the eval level"
    for c in $CONFIGS; do
      [ -d "$e/$c" ] || { err "$n: missing config '$c/'"; continue; }
      runs=("$e/$c"/run-*)
      if [ ! -e "${runs[0]}" ]; then
        err "$n/$c: no run-* directory — the aggregator skips a config without one, which is how a whole arm goes missing"
        continue
      fi
      for r in "$e/$c"/run-*/; do
        rn="$(basename "$r")"
        g="$r/grading.json"
        if [ ! -f "$g" ]; then err "$n/$c/$rn: no grading.json"; continue; fi
        python3 - "$g" "$n/$c/$rn" <<'PY' || fail=1
import json, sys
path, label = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(path))
except Exception as exc:
    print(f"  ERROR  {label}: grading.json is not valid JSON ({exc})"); sys.exit(1)
s = d.get("summary")
if not isinstance(s, dict):
    print(f"  ERROR  {label}: grading.json has no 'summary' object — the aggregator "
          f"reads pass_rate/passed/failed/total from there and silently scores 0 without it")
    sys.exit(1)
missing = [k for k in ("pass_rate", "passed", "failed", "total") if k not in s]
if missing:
    print(f"  ERROR  {label}: summary is missing {missing}"); sys.exit(1)
exps = d.get("expectations")
if not isinstance(exps, list) or not exps:
    print(f"  ERROR  {label}: no expectations array"); sys.exit(1)
bad = [i for i, e in enumerate(exps)
       if not all(k in e for k in ("text", "passed", "evidence"))]
if bad:
    print(f"  ERROR  {label}: expectations {bad} lack text/passed/evidence — "
          f"the viewer reads those exact field names"); sys.exit(1)
if s["total"] != len(exps):
    print(f"  ERROR  {label}: summary.total={s['total']} but {len(exps)} expectations")
    sys.exit(1)
PY
        [ -f "$r/timing.json" ] || printf '  WARN   %s: no timing.json — tokens and duration come only from the task notification, and it does not arrive twice\n' "$n/$c/$rn"
      done
    done
  done
  [ "$fail" = 0 ] && printf '\nLayout is what the aggregator expects.\n' \
                  || printf '\nFix the errors above before aggregating; the aggregator will not report them.\n'
  exit "$fail"
  ;;

discriminate)
  # An assertion that lands the same way in every arm told you nothing about the
  # skill: it is measuring the model, the task, or itself. Cheap to compute and
  # easy to skip, which is exactly why it is a command and not a paragraph.
  python3 - "$dir" "$CONFIGS" <<'PY'
import json, pathlib, sys
root, configs = pathlib.Path(sys.argv[1]), sys.argv[2].split()
any_eval = False
for e in sorted(root.glob("eval-*")):
    arms = {}
    for c in configs:
        for g in sorted((e / c).glob("run-*/grading.json")):
            arms.setdefault(c, []).append(json.loads(g.read_text())["expectations"])
    if len(arms) < 2:
        continue
    any_eval = True
    n = len(next(iter(arms.values()))[0])
    print(f"\n{e.name}")
    dead = 0
    for i in range(n):
        per = {c: {r[i]["passed"] for r in runs} for c, runs in arms.items()}
        flat = {v for s in per.values() for v in s}
        text = next(iter(arms.values()))[0][i]["text"]
        if len(flat) == 1:
            dead += 1
            verdict = "all PASS" if True in flat else "all FAIL"
            print(f"  measures nothing ({verdict:8}) {text[:66]}")
        else:
            print(f"  DISCRIMINATES            {text[:66]}")
    print(f"  -> {dead}/{n} assertions measured nothing about the skill")
if not any_eval:
    print("No eval with two or more configs graded yet.")
PY
  exit 0
  ;;

*) echo "Unknown command: $cmd (init|check|discriminate)" >&2; exit 64 ;;
esac
