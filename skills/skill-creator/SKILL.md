---
name: skill-creator
description: Use when creating a new agent skill from scratch, scaffolding a SKILL.md, validating a skill against the agentskills.io specification, improving a skill from its recorded feedback, or packaging a skill for distribution. Also use when the user mentions skill frontmatter, SKILL.md, progressive disclosure, allowed-tools, or reports that a skill never triggers or triggers on the wrong things.
license: MIT
compatibility: Requires bash and awk, plus a writable skills directory. Optionally uses the skills-ref CLI when installed.
metadata:
  author: rolandbotka
  version: "1.0"
  spec: https://agentskills.io/specification
---

# skill-creator

Builds skills that conform to the [agentskills.io specification](https://agentskills.io/specification)
and to one added convention: **anything a run produces is prefixed with `_`**.

Core principle: a skill directory should be readable at a glance as two separate things —
the skill (`SKILL.md`, `scripts/`, `references/`, `assets/`) and its exhaust
(`_artifacts/`, `_feedback/`, `_memory/`). Never mix them.

## Which mode?

| User says… | Mode |
|---|---|
| "make a skill for X", "I need a skill that…" | **Create** |
| "check this skill", "is this valid", "why doesn't it trigger" | **Validate** |
| "improve this skill", "what went wrong with it", "read the feedback" | **Harvest** |
| "share this skill", "publish it", "get it ready to distribute" | **Package** |

Read `references/spec.md` before writing any frontmatter. Read
`references/conventions.md` before creating any directory.

---

## Layout convention

```
my-skill/
├── SKILL.md          # required
├── scripts/          # executable code the skill runs
├── references/       # docs loaded on demand
├── assets/           # templates, schemas, images
├── _artifacts/       # OUTPUT of runs — gitignored
├── _feedback/        # friction notes — COMMITTED
└── _memory/          # state carried between runs — gitignored
```

Unprefixed = the skill. Underscore-prefixed = what it produced.
A reader, a `.gitignore`, and a packaging script can all tell them apart with one rule.

Never create an underscore directory the skill has no mechanism to write to.
Empty `_artifacts/` in a skill that produces nothing is noise, not convention.

---

## Mode 1: Create

**Interview first.** A skill's `description` decides whether it is ever loaded,
and it cannot be written from a one-line request. Follow
`references/interview.md` — it lists the six questions that determine whether
the skill works, and the rule for skipping the ones already answered.

Then:

1. Run `scripts/scaffold.sh <skill-name> [parent-dir]` to build the tree.
2. Read `references/craft.md` and write `SKILL.md` from `assets/SKILL.md.template`.
3. Run `scripts/validate.sh <path>` and fix every violation before reporting done.

Step 2 is where most skills go wrong: valid frontmatter, body that doesn't bind.
Before writing any rule, classify the failure it targets — a prohibition aimed at
a wrong-shaped output produces *more* of what you were trying to prevent. The
table in `references/craft.md` maps failure types to the form that fixes them.

**Do not claim the skill is finished until `validate.sh` exits 0.** Writing the
file is not the deliverable; a file that passes validation is.

### Writing the description

The description is the only part loaded into every conversation. It must state
**when to use the skill**, not what the skill does internally.

```yaml
# BAD — summarizes the procedure; agents follow the summary instead of reading the skill
description: Creates skills by interviewing the user, scaffolding the directory, then validating

# BAD — vague, matches nothing
description: Helps with skills

# GOOD — triggering conditions, concrete keywords, no workflow
description: Use when creating a new agent skill, validating a SKILL.md against the spec,
  or when the user reports that a skill never triggers
```

Include the words a user would actually type, including error strings and symptoms.
Third person. Under 500 characters where possible; 1024 is the hard cap.

### Where content goes

| Content | Location |
|---|---|
| Decision rules, the procedure itself | `SKILL.md` inline |
| Reference over ~100 lines | `references/<topic>.md` |
| Anything deterministic enough to check mechanically | `scripts/` — not prose |
| Templates the skill fills in | `assets/` |

Keep `SKILL.md` under 500 lines and file references one level deep.
If a rule can be enforced by a regex, put it in `validate.sh` instead of writing it down.

---

## Mode 2: Validate

```bash
scripts/validate.sh <path-to-skill>
```

Checks frontmatter against the spec, name-to-directory match, line count,
reference existence and depth, and the underscore convention. Exits non-zero on
any ERROR; WARN lines are advisory.

Report violations as `file:line` with the specific constraint broken. If
`skills-ref` is on PATH, `validate.sh` runs it too and folds in its output.

When the complaint is "it never triggers", the bug is almost always the
`description`, not the body. Check it first.

---

## Mode 3: Harvest

This is what makes `_feedback/` worth having. Without it the folder is a graveyard.

1. Read every `_feedback/*.md` with `status: open`.
2. Group by `trigger` — repeated triggers of the same kind point at one missing rule,
   not several.
3. For each group, propose a **specific edit** to the skill: the sentence to add,
   the table row, the check to move into `validate.sh`. Not "clarify the docs".
4. Apply the edits the user approves.
5. Set `status: resolved` and fill `resolved-by` on the entries that edit addressed.
6. Re-run `validate.sh`.

Entries whose fix is "the user changed their mind" get `status: wontfix`. Do not
leave them open — an open entry must mean an unfixed defect, or the queue stops
meaning anything.

See `references/feedback-protocol.md` for the entry format.

---

## Mode 4: Package

```bash
scripts/package.sh <path-to-skill> [out-dir]
```

Validates first and refuses to package a skill that fails. Copies everything
except `_artifacts/`, `_memory/`, `.git/`, and `.DS_Store`. **Keeps `_feedback/`** —
it is the skill's improvement history and should travel with it.

Then scans authored files for absolute home paths and secret-shaped strings and
prints anything it finds. Those are for you to review, not for the script to
decide: read every hit before sharing.

---

## Writing feedback entries

**Write an entry only on friction.** A clean run writes nothing — the absence of
a file is the signal that it went fine. Every-run logging buries the useful
entries and nobody reads the folder twice.

Write an entry when any of these happen, in the skill's own `_feedback/`:

| Trigger | Meaning |
|---|---|
| `user-correction` | The user redirected you. Highest signal — this is ground truth, not self-assessment. |
| `step-failure` | A documented step errored or produced the wrong result. |
| `ambiguity` | Two readings of the skill were equally defensible. |
| `guess` | Required information the skill never specified; you picked something. |

Use `assets/feedback-entry.template.md`. One file per entry, timestamped —
never append to a shared file, since parallel runs will clobber each other.

The `## What the skill should have said instead` section is required and must
contain proposed wording. An entry without it is a complaint; an entry with it
is a patch waiting to be applied.

**This applies to skill-creator itself.** If the user corrects your interview
assumptions or your draft description, write the entry into this skill's own
`_feedback/` directory.

---

## Red flags — stop

- About to report a skill as done without running `validate.sh`
- Writing a `description` that describes the procedure rather than the trigger
- Creating `_artifacts/` or `_memory/` when nothing writes to them
- Writing a rule into prose that a regex in `validate.sh` could enforce
- Skipping the interview because the request "seems clear" — it answers at most two of the six questions
- Writing a feedback entry for a run that went fine
- Harvesting feedback into "improve clarity" instead of a specific edit
- Marking entries resolved without making the edit

## Reference files

| File | Read when |
|---|---|
| `references/spec.md` | Writing or checking any frontmatter |
| `references/conventions.md` | Laying out a directory, choosing where content goes |
| `references/interview.md` | Starting Create mode |
| `references/craft.md` | Writing the body — choosing the form a rule should take |
| `references/feedback-protocol.md` | Writing or harvesting a feedback entry |

## Scripts

| Script | Does |
|---|---|
| `scripts/scaffold.sh <name> [parent] [--artifacts] [--memory]` | Builds a spec-conformant tree. Validates the name, refuses to overwrite, creates `_artifacts/`/`_memory/` only when asked. |
| `scripts/validate.sh <path>` | Spec + convention checks. Exit 1 on any ERROR. |
| `scripts/package.sh <path> [out]` | Validates, strips runtime output, scans for leaked paths and secrets. |
