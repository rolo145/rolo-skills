#!/usr/bin/env bash
# Report what changed in Anthropic's official skill-creator, so the delegation in
# Tune and Evaluate mode can be kept current without copying that skill's prose
# into this one.
#
# Three records, because "reviewed" means two different things depending on who
# is asking, and one file cannot honestly hold both:
#
#   scripts/official-baseline.tsv    committed, ships with the skill — the upstream
#                                    the Mode 3 and Mode 4 invocations were WRITTEN
#                                    AGAINST. Only this skill's maintainer moves it,
#                                    with --pin, after updating those modes.
#   _artifacts/official-reviewed.tsv gitignored, per machine — what YOU last looked
#                                    at, written by --accept. Takes precedence when
#                                    present, so your own review point is not mixed
#                                    up with the maintainer's.
#   _artifacts/official-snapshot/    gitignored — a copy of the upstream at that
#                                    point, so the report can offer a real diff.
#
# On a fresh install only the shipped pin exists, which is the useful default: the
# first run answers "has upstream moved since this skill's glue was written?"
#
# Usage:
#   check-official.sh            compare upstream against your review point
#   check-official.sh --accept   record the current upstream as reviewed (local)
#   check-official.sh --pin      maintainer: move the shipped pin here too
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$HERE")"
PINNED="$HERE/official-baseline.tsv"
REVIEWED="$SKILL_DIR/_artifacts/official-reviewed.tsv"
SNAPSHOT="$SKILL_DIR/_artifacts/official-snapshot"

OFFICIAL="$("$HERE/find-official.sh")" || exit 1

fingerprint() {
  # sha256<TAB>relpath, sorted, skipping caches and junk.
  (cd "$1" && find . -type f \
      ! -path './__pycache__/*' ! -name '*.pyc' ! -name '.DS_Store' \
      -print0 | sort -z |
    while IFS= read -r -d '' f; do
      printf '%s\t%s\n' "$(shasum -a 256 "$f" | cut -d' ' -f1)" "${f#./}"
    done)
}

record_local() {
  mkdir -p "$SKILL_DIR/_artifacts"
  fingerprint "$OFFICIAL" > "$REVIEWED"
  rm -rf "$SNAPSHOT"
  mkdir -p "$SNAPSHOT"
  (cd "$OFFICIAL" && tar cf - --exclude='__pycache__' --exclude='*.pyc' .) |
    (cd "$SNAPSHOT" && tar xf -)
}

case "${1:-}" in
  --accept)
    record_local
    printf 'Recorded %s files as reviewed on this machine.\n' \
      "$(wc -l < "$REVIEWED" | tr -d ' ')"
    printf '  upstream: %s\n  reviewed: %s (gitignored)\n' "$OFFICIAL" "$REVIEWED"
    exit 0
    ;;
  --pin)
    record_local
    cp "$REVIEWED" "$PINNED"
    printf 'Pinned %s files as what this skill delegates against.\n' \
      "$(wc -l < "$PINNED" | tr -d ' ')"
    printf '  upstream: %s\n  pinned:   %s (commit this)\n' "$OFFICIAL" "$PINNED"
    printf '\nOnly do this after checking that the Mode 3 and Mode 4 invocations\n'
    printf 'still match what those scripts expect — the pin is a claim that they do.\n'
    exit 0
    ;;
  "") ;;
  *) printf 'Unknown option: %s\nUsage: %s [--accept|--pin]\n' "$1" "$0" >&2; exit 64 ;;
esac

if [ -f "$REVIEWED" ]; then
  BASE="$REVIEWED"; SINCE="since you last reviewed it"; CLEAN="matches what you reviewed"
elif [ -f "$PINNED" ]; then
  BASE="$PINNED"
  SINCE="since this skill's delegation was written against it"
  CLEAN="matches what this skill delegates against"
else
  cat >&2 <<MSG
No pin and no local review point.

  The shipped pin is missing, which should not happen in a released copy of this
  skill. Review the upstream once and record it:
    $0 --accept

  upstream: $OFFICIAL
MSG
  exit 1
fi

CUR="$(mktemp)"; trap 'rm -f "$CUR"' EXIT
fingerprint "$OFFICIAL" > "$CUR"

if cmp -s "$BASE" "$CUR"; then
  printf 'Up to date — upstream %s (%s files).\n' "$CLEAN" "$(wc -l < "$BASE" | tr -d ' ')"
  exit 0
fi

printf 'Upstream has moved %s.\n  %s\n\n' "$SINCE" "$OFFICIAL"

# Classify by path, because that is what decides the response: a new file under
# scripts/, agents/ or eval-viewer/ is machinery to delegate to, while changed
# prose is a judgement call about whether this skill wants the same idea.
classify() {
  case "$1" in
    scripts/*|agents/*|eval-viewer/*) echo "machinery — candidate to delegate to" ;;
    references/*|assets/*)            echo "bundled resource" ;;
    SKILL.md)                         echo "their guidance — adopt the idea, not the words" ;;
    *)                                echo "" ;;
  esac
}

report() {
  local mark="$1" path="$2" note
  note="$(classify "$path")"
  if [ -n "$note" ]; then
    printf '  %s %-34s  %s\n' "$mark" "$path" "$note"
  else
    printf '  %s %s\n' "$mark" "$path"
  fi
}

while IFS= read -r path; do report '+' "$path"; done < <(
  comm -13 <(cut -f2 "$BASE" | sort) <(cut -f2 "$CUR" | sort))
while IFS= read -r path; do report '-' "$path"; done < <(
  comm -23 <(cut -f2 "$BASE" | sort) <(cut -f2 "$CUR" | sort))
while IFS= read -r path; do report '~' "$path"; done < <(
  comm -12 <(cut -f2 "$BASE" | sort) <(cut -f2 "$CUR" | sort) |
  while IFS= read -r f; do
    a="$(grep -F "	$f" "$BASE" | cut -f1)"
    b="$(grep -F "	$f" "$CUR" | cut -f1)"
    [ "$a" = "$b" ] || printf '%s\n' "$f"
  done)

printf '\n  + added   - removed   ~ changed\n'
if [ -d "$SNAPSHOT" ]; then
  printf '\nFull diff:  diff -ru %s %s\n' "$SNAPSHOT" "$OFFICIAL"
else
  printf '\nNo local snapshot to diff against — it is gitignored runtime output, so a\n'
  printf 'freshly installed copy has none until the first --accept.\n'
fi
printf 'Once reviewed:  %s --accept\n' "$0"
exit 2
