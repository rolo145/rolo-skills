#!/usr/bin/env bash
# Scaffold a spec-conformant skill directory.
# Usage: scaffold.sh <skill-name> [parent-dir] [--artifacts] [--memory] [--feedback]
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$SELF_DIR/../assets"

NAME=""
PARENT="$HOME/.agents/skills"
WANT_ARTIFACTS=0
WANT_MEMORY=0
WANT_FEEDBACK=0

for arg in "$@"; do
  case "$arg" in
    --artifacts) WANT_ARTIFACTS=1 ;;
    --memory)    WANT_MEMORY=1 ;;
    --feedback)  WANT_FEEDBACK=1 ;;
    -h|--help)
      sed -n '2,3p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      if [ -z "$NAME" ]; then NAME="$arg"; else PARENT="$arg"; fi ;;
  esac
done

if [ -z "$NAME" ]; then
  echo "usage: scaffold.sh <skill-name> [parent-dir] [--artifacts] [--memory] [--feedback]" >&2
  exit 2
fi

# Spec: 1-64 chars, lowercase alnum and hyphens, no leading/trailing/consecutive hyphens.
if ! printf '%s' "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "ERROR: invalid skill name '$NAME'" >&2
  echo "       must match ^[a-z0-9]+(-[a-z0-9]+)*\$ (lowercase, no leading/trailing/double hyphens)" >&2
  exit 1
fi
if [ ${#NAME} -gt 64 ]; then
  echo "ERROR: name is ${#NAME} chars; spec maximum is 64" >&2
  exit 1
fi

DEST="$PARENT/$NAME"
if [ -e "$DEST" ]; then
  echo "ERROR: $DEST already exists — refusing to overwrite" >&2
  exit 1
fi

mkdir -p "$DEST"/{scripts,references,assets}
if [ "$WANT_ARTIFACTS" -eq 1 ]; then mkdir -p "$DEST/_artifacts"; fi
if [ "$WANT_MEMORY" -eq 1 ];    then mkdir -p "$DEST/_memory"; fi
if [ "$WANT_FEEDBACK" -eq 1 ];  then mkdir -p "$DEST/_feedback"; fi

# The Feedback section of the template is delimited by sentinels: keep its body
# only when the skill has a _feedback/ to write into. The sentinels never ship.
sed "s/SKILL_NAME/$NAME/g" "$ASSETS/SKILL.md.template" \
  | awk -v keep="$WANT_FEEDBACK" '
      $0 == "<!-- FEEDBACK:START -->" { inblock=1; next }
      $0 == "<!-- FEEDBACK:END -->"   { inblock=0; next }
      inblock && keep == 0            { next }
      { print }
    ' > "$DEST/SKILL.md"

cp "$ASSETS/gitignore.template" "$DEST/.gitignore"

if [ "$WANT_FEEDBACK" -eq 1 ]; then
cp "$ASSETS/feedback-entry.template.md" "$DEST/assets/feedback-entry.template.md"
cat > "$DEST/_feedback/README.md" <<READMEEOF
# _feedback

Friction notes for \`$NAME\`, written **only when a run hits a problem** — a user
correction, a failed step, an ambiguity in the skill, or a guess you had to make.
A clean run writes nothing here; the absence of a file is the signal.

One file per entry, named \`YYYY-MM-DD-HHMMSS-short-slug.md\`. Never append to a
shared file — parallel runs clobber each other.

Use \`assets/feedback-entry.template.md\`. The
\`## What the skill should have said instead\` section is required — an entry
without it is a complaint, not a patch.

Triggers: \`user-correction\` (strongest — ground truth, not self-assessment),
\`step-failure\`, \`ambiguity\`, \`guess\`.

Harvest with skill-creator: it groups open entries, proposes concrete edits, and
marks them resolved.

    grep -l 'status: open' _feedback/*.md

Underscore prefix means runtime output, not part of the skill. This directory is
the exception that stays committed — it is the skill's improvement history and
should travel with it.
READMEEOF
fi

echo "Created $DEST"
find "$DEST" -mindepth 1 | sed "s|$DEST|  .|" | sort
echo
echo "Next:"
echo "  1. Write the description — triggering conditions only, no workflow summary."
echo "  2. Fill in SKILL.md."
echo "  3. $SELF_DIR/validate.sh $DEST"
if [ "$WANT_ARTIFACTS" -eq 0 ]; then echo "  (_artifacts/ not created — pass --artifacts if the skill writes output files)"; fi
if [ "$WANT_MEMORY" -eq 0 ];    then echo "  (_memory/ not created — pass --memory if the skill carries state between runs)"; fi
if [ "$WANT_FEEDBACK" -eq 0 ];  then echo "  (_feedback/ not created — pass --feedback if the skill should record friction for later harvest)"; fi
exit 0
