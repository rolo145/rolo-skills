#!/usr/bin/env bash
# Validate a skill against the agentskills.io specification and the
# underscore-prefix layout convention.
# Usage: validate.sh <path-to-skill-dir> [--errors-only]
# Exit: 0 = no errors (warnings allowed), 1 = at least one ERROR, 2 = bad usage.
#
# --errors-only prints nothing unless something is actually broken, so the script
# can run unattended — from an editor hook, say — without adding noise to a clean
# file.

set -uo pipefail

QUIET=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --errors-only|-q) QUIET=1 ;;
    *) ARGS+=("$a") ;;
  esac
done

DIR="${ARGS[0]:-}"
if [ -z "$DIR" ]; then
  echo "usage: validate.sh <path-to-skill-dir> [--errors-only]" >&2
  exit 2
fi
if [ ! -d "$DIR" ]; then
  echo "usage: validate.sh <path-to-skill-dir> [--errors-only]  ('$DIR' is not a directory)" >&2
  exit 2
fi
# Resolve so that '.', '..' and trailing slashes still yield a real directory
# name — the spec requires `name` to equal the directory name, and `basename .`
# is not it.
DIR="$(cd "$DIR" && pwd -P)"

SKILL="$DIR/SKILL.md"
BASE="$(basename "$DIR")"
ERRORS=0
WARNINGS=0

err()  { echo "ERROR   $*"; ERRORS=$((ERRORS+1)); }
warn() { [ "$QUIET" -eq 1 ] || echo "WARN    $*"; WARNINGS=$((WARNINGS+1)); }
ok()   { [ "$QUIET" -eq 1 ] || echo "ok      $*"; }
note() { [ "$QUIET" -eq 1 ] || echo "note    $*"; }

[ "$QUIET" -eq 1 ] || echo "Validating $DIR"
echo

# ---------------------------------------------------------------- SKILL.md
if [ ! -f "$SKILL" ]; then
  err "SKILL.md missing — a skill must contain SKILL.md at its root"
  echo; echo "$ERRORS error(s), $WARNINGS warning(s)"; exit 1
fi

if [ "$(head -n1 "$SKILL")" != "---" ]; then
  err "SKILL.md:1  file must open with '---' (YAML frontmatter)"
  echo; echo "$ERRORS error(s), $WARNINGS warning(s)"; exit 1
fi

FM="$(awk 'NR==1&&$0=="---"{next} $0=="---"{exit} {print}' "$SKILL")"
if [ -z "$FM" ]; then
  err "SKILL.md  frontmatter block is empty or unterminated"
  echo; echo "$ERRORS error(s), $WARNINGS warning(s)"; exit 1
fi

# Read a top-level scalar, joining YAML continuation lines.
fm_get() {
  printf '%s\n' "$FM" | awk -v k="$1" '
    $0 ~ "^"k":" { sub("^"k":[ \t]*",""); print; grab=1; next }
    grab && /^[ \t]+[^ \t]/ && $0 !~ /^[ \t]+[A-Za-z0-9_-]+:/ { sub(/^[ \t]+/," "); printf "%s",$0; next }
    grab { exit }
  ' | sed 's/^"\(.*\)"$/\1/; s/^'"'"'\(.*\)'"'"'$/\1/'
}
fm_has() { printf '%s\n' "$FM" | grep -qE "^$1:"; }

# ------------------------------------------------------------------- name
if ! fm_has name; then
  err "SKILL.md  frontmatter missing required field: name"
else
  NAME="$(fm_get name)"
  if [ -z "$NAME" ]; then
    err "SKILL.md  'name' is empty"
  else
    NAME_OK=1
    if ! printf '%s' "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      err "name '$NAME' violates spec — must match ^[a-z0-9]+(-[a-z0-9]+)*\$ (lowercase alnum and single hyphens, no leading/trailing hyphen)"
      NAME_OK=0
    fi
    if [ ${#NAME} -gt 64 ]; then
      err "name is ${#NAME} chars — spec maximum is 64"
      NAME_OK=0
    fi
    if [ "$NAME" != "$BASE" ]; then
      err "name '$NAME' does not match parent directory '$BASE' — the spec requires them to be identical"
      NAME_OK=0
    fi
    if [ "$NAME_OK" -eq 1 ]; then
      ok "name '$NAME' valid and matches directory"
    fi
  fi
fi

# ------------------------------------------------------------ description
if ! fm_has description; then
  err "SKILL.md  frontmatter missing required field: description"
else
  DESC="$(fm_get description)"
  DLEN=${#DESC}
  if [ "$DLEN" -eq 0 ]; then
    err "'description' is empty — it is the only field loaded into every conversation"
  elif [ "$DLEN" -gt 1024 ]; then
    err "description is $DLEN chars — spec maximum is 1024"
  else
    if [ "$DLEN" -gt 500 ]; then
      warn "description is $DLEN chars — under 500 is recommended (1024 is the hard cap)"
    fi
    if [ "$DLEN" -lt 40 ]; then
      warn "description is only $DLEN chars — likely too vague to trigger reliably; name concrete situations and keywords"
    fi
    if ! printf '%s' "$DESC" | grep -qiE '\b(use when|when the user|when you|use this)\b'; then
      warn "description does not state a triggering condition — start with 'Use when …' so agents can tell if it applies"
    fi
    ok "description present ($DLEN chars)"
  fi
fi

# ---------------------------------------------------------- optional fields
if fm_has compatibility; then
  COMPAT="$(fm_get compatibility)"
  if [ ${#COMPAT} -eq 0 ]; then
    err "compatibility is present but empty — omit the field instead"
  elif [ ${#COMPAT} -gt 500 ]; then
    err "compatibility is ${#COMPAT} chars — spec maximum is 500"
  fi
fi

# metadata values must be strings; bare numbers parse as floats/ints
BADMETA="$(printf '%s\n' "$FM" | awk '
  /^metadata:/ {inm=1; next}
  inm && /^[A-Za-z0-9_-]+:/ {inm=0}
  inm && /^[ \t]+[A-Za-z0-9_.-]+:[ \t]*[0-9]+(\.[0-9]+)?[ \t]*$/ {gsub(/^[ \t]+/,""); print}
')"
if [ -n "$BADMETA" ]; then
  while IFS= read -r line; do
    warn "metadata value must be a string — quote it: $line  ->  ${line%%:*}: \"${line#*: }\""
  done <<< "$BADMETA"
fi

# ------------------------------------------------------------- body length
LINES=$(wc -l < "$SKILL" | tr -d ' ')
if [ "$LINES" -gt 500 ]; then
  warn "SKILL.md is $LINES lines — keep it under 500 and move detail into references/"
else
  ok "SKILL.md is $LINES lines"
fi

# ------------------------------------------------------- context economy
# The body is billed on every activation, so what matters is not its absolute
# size but whether a typical run needs all of it. A large body with nothing
# underneath it means detail was never pushed down.
if [ "$LINES" -gt 300 ] && [ ! -d "$DIR/references" ]; then
  warn "SKILL.md is $LINES lines with no references/ — every run pays for all of it; move mode-specific detail into references/"
fi
for f in "$DIR"/references/*.md; do
  [ -f "$f" ] || continue
  RL=$(wc -l < "$f" | tr -d ' ')
  if [ "$RL" -gt 500 ]; then
    warn "references/$(basename "$f") is $RL lines — split it, or a run needing one section pays for all of them"
  fi
done

# --------------------------------------------------------- file references
MDREFS="$(grep -oE '\]\([^)#][^)]*\)' "$SKILL" 2>/dev/null | sed 's/^](//; s/)$//' || true)"
# Also catch paths mentioned in backticks, e.g. `references/spec.md` or `scripts/run.sh`.
TICKREFS="$(grep -oE '`(scripts|references|assets)/[A-Za-z0-9._/-]+`' "$SKILL" 2>/dev/null | tr -d '`' || true)"
REFS="$(printf '%s\n%s\n' "$MDREFS" "$TICKREFS" | grep -v '^$' | sort -u || true)"
if [ -n "$REFS" ]; then
  while IFS= read -r r; do
    case "$r" in
      http://*|https://*|mailto:*|"") continue ;;
    esac
    r="${r%%#*}"
    [ -z "$r" ] && continue
    if [ ! -e "$DIR/$r" ]; then
      err "SKILL.md references '$r' which does not exist"
    fi
    depth=$(printf '%s' "$r" | tr -cd '/' | wc -c | tr -d ' ')
    if [ "$depth" -gt 1 ]; then
      warn "reference '$r' is more than one level deep — keep references flat from SKILL.md"
    fi
  done <<< "$REFS"
fi

# ----------------------------------------------------- layout conventions
for d in "$DIR"/*/; do
  [ -d "$d" ] || continue
  n="$(basename "$d")"
  case "$n" in
    scripts|references|assets) ;;
    _*) ;;
    *) warn "directory '$n/' is neither a spec directory (scripts/ references/ assets/) nor runtime output — prefix it with '_' if a run produces it" ;;
  esac
done

if [ ! -d "$DIR/_feedback" ]; then
  # Opting out is legitimate. What is not legitimate is a SKILL.md that tells
  # its agent to write entries into a directory the skill does not have.
  if grep -q '_feedback/' "$SKILL"; then
    warn "SKILL.md references _feedback/ but the directory does not exist — create it (scaffold.sh --feedback) or drop the instruction"
  else
    note "no _feedback/ — this skill does not record friction (opt in with scaffold.sh --feedback)"
  fi
else
  OPEN=0
  for f in "$DIR"/_feedback/*.md; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "README.md" ] && continue
    if grep -qE '^status:[ ]*open' "$f"; then OPEN=$((OPEN+1)); fi
  done
  if [ "$OPEN" -gt 0 ]; then
    ok "_feedback/ present — $OPEN open entr$([ "$OPEN" -eq 1 ] && echo y || echo ies) awaiting harvest"
  else
    ok "_feedback/ present — no open entries"
  fi
fi

if [ ! -f "$DIR/.gitignore" ]; then
  warn "no .gitignore — _artifacts/ should not be committed"
else
  for pat in _artifacts/; do
    if ! grep -qF "$pat" "$DIR/.gitignore"; then
      warn ".gitignore does not cover '$pat'"
    fi
  done
  if [ -d "$DIR/_feedback" ] && grep -qE '^_feedback/' "$DIR/.gitignore"; then
    warn ".gitignore excludes _feedback/ — it should be committed so a shared skill carries its improvement history"
  fi
fi

for d in _artifacts; do
  if [ -d "$DIR/$d" ] && [ -z "$(ls -A "$DIR/$d" 2>/dev/null)" ]; then
    warn "$d/ exists but is empty — create it only when the skill actually writes there"
  fi
done

# --------------------------------------------------------- reference impl
if command -v skills-ref >/dev/null 2>&1; then
  echo
  echo "skills-ref validate:"
  if skills-ref validate "$DIR"; then
    ok "skills-ref passed"
  else
    err "skills-ref reported violations (above)"
  fi
fi

if [ "$QUIET" -eq 0 ] || [ "$ERRORS" -gt 0 ]; then
  echo
  echo "$ERRORS error(s), $WARNINGS warning(s)"
fi
[ "$ERRORS" -gt 0 ] && exit 1
exit 0
