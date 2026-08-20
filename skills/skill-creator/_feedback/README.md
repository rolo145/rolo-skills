# _feedback

Friction notes for `skill-creator`, written **only when a run hits a problem** —
a user correction, a failed step, an ambiguity in the skill, or a guess you had
to make. A clean run writes nothing here; the absence of a file is the signal.

One file per entry, named `YYYY-MM-DD-HHMMSS-short-slug.md`. Never append to a
shared file — parallel runs clobber each other.

Use `assets/feedback-entry.template.md`. The
`## What the skill should have said instead` section is required.

Harvest with skill-creator's Harvest mode: it groups open entries, proposes
concrete edits, and marks them resolved.

    grep -l 'status: open' _feedback/*.md

skill-creator is subject to the protocol it installs. When its interview misses
something or its draft description gets corrected, the entry lands here.

Underscore prefix means runtime output, not part of the skill. This directory is
the exception that stays committed — it is the skill's improvement history and
should travel with it.
