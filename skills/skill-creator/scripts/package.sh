#!/usr/bin/env bash
# Produce a distributable copy of a skill: validated, with runtime output stripped.
# Usage: package.sh <skill-dir> [out-dir]
# _artifacts/ is excluded. _feedback/ is kept — it is the skill's
# improvement history and should travel with it.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${1:-}"
OUT="${2:-$PWD/dist}"

if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
  echo "usage: package.sh <skill-dir> [out-dir]" >&2
  exit 2
fi
SRC="${SRC%/}"
NAME="$(basename "$SRC")"
DEST="$OUT/$NAME"

echo "== validating before packaging"
if ! "$SELF_DIR/validate.sh" "$SRC"; then
  echo
  echo "ERROR: refusing to package a skill that fails validation" >&2
  exit 1
fi

if [ -e "$DEST" ]; then
  echo "ERROR: $DEST already exists — remove it or choose another out-dir" >&2
  exit 1
fi

mkdir -p "$DEST"
( cd "$SRC" && tar -cf - \
    --exclude='./_artifacts' \
    --exclude='.DS_Store' --exclude='./.git' . ) | ( cd "$DEST" && tar -xf - )

echo
echo "== packaged to $DEST"
echo "   excluded: _artifacts/  .git/  .DS_Store"
if [ -d "$DEST/_feedback" ]; then
  KEPT=$(find "$DEST/_feedback" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  echo "   kept:     _feedback/ ($KEPT file(s))"
fi

echo
echo "== manual review before you share this"
# Scan authored files only. _feedback/ and references/ legitimately quote paths
# and field names, so they are excluded by PATH — never by line content, which
# would let a real finding hide behind a word in the matched text.
HITS=0
while IFS= read -r line; do
  echo "   $line"; HITS=$((HITS+1))
done < <(find "$DEST" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.py' -o -name '*.js' -o -name '*.json' -o -name '*.yaml' -o -name '*.yml' \) \
           -not -path "$DEST/_feedback/*" -not -path "$DEST/references/*" -print0 2>/dev/null \
         | xargs -0 grep -InE "$HOME|/Users/[a-z]+|(api[_-]?key|secret|token|password)[\"' ]*[:=]" 2>/dev/null \
         | sed "s|^$DEST/||" | head -20)
if [ "$HITS" -eq 0 ]; then
  echo "   no absolute home paths or secret-shaped strings found"
else
  echo
  echo "   ^ check these before distributing — machine-specific paths and credentials"
fi
exit 0
