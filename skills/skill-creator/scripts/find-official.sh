#!/usr/bin/env bash
# Locate Anthropic's official skill-creator inside the installed plugin cache and
# print its directory.
#
# Two things are delegated to that plugin: the description optimiser (Tune) and
# the eval harness (Evaluate). Both are stdlib-only Python, so they run whether
# or not the skill itself is enabled in /plugin — only the files need to be on
# disk, and leaving it disabled keeps its description from competing with this
# skill's for the trigger. The cache path contains a version hash, so it is
# resolved at call time rather than hardcoded.
#
# The plugin cache is the source of truth on purpose. A second copy of the same
# upstream may exist under skills/synced/ from claude.ai account sync; it lags
# the plugin and disappears when the account skill is turned off.
#
# Usage: find-official.sh   -> prints the directory, or exits 1 with guidance.
set -uo pipefail

BEST=""
for root in "$HOME/.claude" "$HOME"/.claude-*; do
  [ -d "$root" ] || continue
  for d in "$root"/plugins/cache/claude-plugins-official/skill-creator/*/skills/skill-creator; do
    [ -f "$d/scripts/run_loop.py" ] || continue
    if [ -z "$BEST" ] || [ "$d" -nt "$BEST" ]; then BEST="$d"; fi
  done
done

if [ -z "$BEST" ]; then
  cat >&2 <<'MSG'
ERROR: Anthropic's official skill-creator plugin is not installed.

  Its description optimiser (Tune) and eval harness (Evaluate) are what this
  skill delegates to. Install the plugin with /plugin; leave the skill itself
  disabled, since nothing here loads it — only its files are read from disk.
MSG
  exit 1
fi

printf '%s\n' "$BEST"
exit 0
