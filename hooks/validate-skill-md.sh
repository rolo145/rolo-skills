#!/usr/bin/env bash
# PostToolUse hook: after a SKILL.md is written or edited, check it against the
# agentskills.io spec and report only what is actually broken.
#
# Advisory by design. Warnings and ok lines are suppressed, so a clean edit — or
# an edit to a skill that does not follow this repo's layout conventions — stays
# completely silent. Only spec ERRORs surface, on stderr with exit 2, which is
# what puts them in front of the agent that just made the edit.
set -uo pipefail

PAYLOAD="$(cat)"

FILE="$(printf '%s' "$PAYLOAD" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print((d.get("tool_input") or {}).get("file_path") or "")
' 2>/dev/null)"

[ -n "$FILE" ] || exit 0
[ "$(basename "$FILE")" = "SKILL.md" ] || exit 0
[ -f "$FILE" ] || exit 0

VALIDATE="${CLAUDE_PLUGIN_ROOT:-}/skills/skill-creator/scripts/validate.sh"
[ -x "$VALIDATE" ] || exit 0

OUT="$("$VALIDATE" "$(dirname "$FILE")" --errors-only 2>&1)" && exit 0

{
  echo "$(basename "$(dirname "$FILE")")/SKILL.md violates the agentskills.io spec:"
  echo "$OUT"
  echo
  echo "Fix these before treating the skill as done."
} >&2
exit 2
