# Feedback protocol

`_feedback/` records where a skill hurt, so it can be improved later from evidence
rather than memory.

**The directory is opt-in.** A skill has one only if it was scaffolded with
`--feedback`, and everything below applies only to skills that have it. If the
running skill has no `_feedback/`, there is nothing to write — surface the
friction to the user instead of creating the folder to hold it.

## Write only on friction

A clean run writes **nothing**. The absence of a file is the signal that the run
went fine.

Logging every run buries the useful entries under "went fine" notes, and a folder
nobody reads twice is worse than no folder — it produces the feeling of having an
improvement process without the substance.

## Triggers

| `trigger` | Write an entry when |
|---|---|
| `user-correction` | The user redirected you mid-run. Ground truth, not self-assessment — the strongest signal available. |
| `step-failure` | A documented step errored, or produced a result the skill said it wouldn't. |
| `ambiguity` | Two readings of the skill were equally defensible and you had to pick. |
| `guess` | The skill never specified something you needed; you chose without guidance. |

`user-correction` outranks the others. An agent judging its own run is a biased
witness; a human saying "no, do it this way" is not.

## Entry format

One file per entry: `_feedback/YYYY-MM-DD-HHMMSS-short-slug.md`.

Never append to a shared `FEEDBACK.md` — parallel runs will clobber each other,
and a per-file layout makes `grep -l 'status: open'` the whole query language.

```markdown
---
date: 2026-08-20T14:32:00Z
skill: my-skill
trigger: user-correction
severity: medium
status: open
resolved-by: ""
---

## What happened

One paragraph. What you did, what the user or the system did in response.

## What the skill should have said instead

Proposed wording, table row, or check. Concrete enough to paste in.
```

`severity`: `low` (cosmetic, slowed you down), `medium` (produced wrong output the
user had to catch), `high` (the skill's stated procedure is wrong or unsafe).

`status`: `open` → `resolved` (edit applied, `resolved-by` filled) or `wontfix`
(the user changed their mind; the skill was not at fault).

## The required section

`## What the skill should have said instead` is mandatory. An entry without it is
a complaint, and complaints do not get acted on — six months later nobody can
reconstruct what the fix was supposed to be.

Forcing the note into the shape of a proposed edit is what makes harvesting cheap
enough to actually happen. If you cannot articulate the fix, the entry is not
ready to write.

## Harvesting

Run when a skill has accumulated open entries, or when the user asks to improve a
skill.

1. Read all `status: open` entries.
2. Group by `trigger`. Three `ambiguity` entries about the same section are one
   missing rule, not three edits.
3. Turn each group into a **specific change**: the sentence to add, the table row,
   the check to move into `validate.sh`. Never "clarify the documentation".
4. Prefer moving a rule into a script over writing it in prose. A rule that exits
   non-zero cannot be skipped; a rule in prose can.
5. Apply approved edits.
6. Set `status: resolved` and fill `resolved-by` on the entries the edit addressed.
7. Re-run `validate.sh`.

Do not mark entries resolved without making the edit, and do not leave a decided
entry open. An open entry must mean an unfixed defect, or the queue stops meaning
anything and the folder becomes the graveyard it was built to avoid.

## Useful queries

```bash
grep -l 'status: open' _feedback/*.md              # what's outstanding
grep -h 'trigger:' _feedback/*.md | sort | uniq -c # where the skill hurts most
grep -l 'severity: high' _feedback/*.md            # fix these first
```
