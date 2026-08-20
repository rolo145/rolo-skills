#!/usr/bin/env bash
# Locate Anthropic's official skill-creator inside the installed plugin cache and
# print its directory.
#
# Only that plugin's description optimiser is delegated to. It is a stdlib-only
# Python tool set, so it runs whether or not the skill itself is enabled in
# /plugin — only the files need to be on disk. The cache path contains a version
# hash, so it is resolved at call time rather than hardcoded.
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

  Its description optimiser is the only thing this skill delegates to. Install
  the plugin with /plugin; the skill itself can stay disabled, since nothing here
  loads it — only its files are read from disk.
MSG
  exit 1
fi

printf '%s\n' "$BEST"
exit 0
