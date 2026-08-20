---
name: skill-creator
description: Use when creating a new agent skill from scratch, scaffolding a SKILL.md, validating a skill against the agentskills.io specification, improving a skill from its recorded feedback, or packaging a skill for distribution. Also use when the user mentions skill frontmatter, SKILL.md, progressive disclosure, allowed-tools, or reports that a skill never triggers or triggers on the wrong things.
license: MIT
compatibility: Requires bash and awk, plus a writable skills directory. Optionally uses the skills-ref CLI when installed.
metadata:
  author: rolandbotka
  spec: https://agentskills.io/specification
---

# skill-creator

Builds skills that conform to the [agentskills.io specification](https://agentskills.io/specification)
and to one added convention: **anything a run produces is prefixed with `_`**.

Core principle: a skill directory should be readable at a glance as two separate things —
the skill (`SKILL.md`, `scripts/`, `references/`, `assets/`) and its exhaust
(`_artifacts/`, `_feedback/`). Never mix them.

## Which mode?

| User says… | Mode | Read first |
|---|---|---|
| "make a skill for X", "I need a skill that…" | **Create** | `references/interview.md`, then `references/craft.md` + `references/economy.md` |
| "check this skill", "is this valid" | **Validate** | nothing — run the script |
| "why doesn't it trigger", "it fires on the wrong things" | **Tune** | nothing — run the script |
| "improve this skill", "what went wrong with it", "read the feedback" | **Harvest** | `references/feedback-protocol.md` |
| "share this skill", "publish it", "get it ready to distribute" | **Package** | nothing — run the script |

Add `references/spec.md` before writing or checking any frontmatter, and
`references/conventions.md` before creating any directory. Load nothing else —
the body is paid on every run, and this table is the skill's own economy rule
applied to itself.

---

## Layout convention

```
my-skill/
├── SKILL.md          # required
├── scripts/          # executable code the skill runs
├── references/       # docs loaded on demand
├── assets/           # templates, schemas, images
├── _artifacts/       # opt-in — OUTPUT of runs, gitignored
└── _feedback/        # opt-in — friction notes, COMMITTED
```

Unprefixed = the skill. Underscore-prefixed = what it produced.
A reader, a `.gitignore`, and a packaging script can all tell them apart with one rule.

**Both underscore directories are opt-in.** Never create one the skill has no
mechanism to write to — an empty `_artifacts/` in a skill that produces nothing is
noise, not convention, and the same is true of `_feedback/` in a skill nobody will
iterate on. `scaffold.sh` creates each only when asked: `--artifacts`,
`--feedback`.

---

## Mode 1: Create

**Interview first.** A skill's `description` decides whether it is ever loaded,
and it cannot be written from a one-line request. Follow
`references/interview.md` — it lists the six questions that determine whether
the skill works, and the rule for skipping the ones already answered.

Then:

1. Run `scripts/scaffold.sh <skill-name> [parent-dir]` to build the tree, adding
   `--artifacts` or `--feedback` for the underscore directories the interview
   established this skill needs.
2. Read `references/craft.md` and write `SKILL.md` from `assets/SKILL.md.template`.
3. Run `scripts/validate.sh <path>` and fix every violation before reporting done.

Step 2 is where most skills go wrong: valid frontmatter, body that doesn't bind.
Before writing any rule, classify the failure it targets — a prohibition aimed at
a wrong-shaped output produces *more* of what you were trying to prevent. The
table in `references/craft.md` maps failure types to the form that fixes them.

**Do not claim the skill is finished until `validate.sh` exits 0.** Writing the
file is not the deliverable; a file that passes validation is.

### Keeping it cheap to run

The body is paid on every activation and the `description` on every conversation,
so a skill's cost is a design property, not an afterthought. Read
`references/economy.md` before writing the body. The two rules that decide most
of it: detail only one mode uses belongs in `references/<mode>.md`, not inline;
and anything a script can decide should print a verdict instead of being
explained in prose, because a script's source is never loaded and never skipped.

`references/economy.md` also covers when a skill should tell its agent to
dispatch a subagent — the honest version, where a subagent costs *more* in total
and buys a smaller calling context, so it earns its place only when the work
throws off bulk nobody needs to keep.

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
| Detail only one mode uses | `references/<mode>.md` — the body is billed on every run |
| Anything deterministic enough to check mechanically | `scripts/` — not prose |
| Templates the skill fills in | `assets/` |

Keep `SKILL.md` under 500 lines and file references one level deep. The line
count is only a proxy; the question that matters is what fraction of the body a
typical run actually uses — see `references/economy.md`.
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

## Mode 3: Tune the description

A description that never fires fails **silently** — no transcript anywhere
records that a skill was not loaded. Re-reading it yourself cannot catch that:
you wrote it, so you read it the way you meant it. Measure it instead.

Anthropic's official skill-creator plugin ships a description optimiser. It runs
a set of trigger queries against a live `claude -p`, splits them train/test,
proposes rewrites, and returns the variant scoring best on the held-out half.
Delegating this is deliberate — it is a measurement harness rather than guidance,
so there is nothing here to keep in sync with it.

```bash
OFFICIAL="$(scripts/find-official.sh)" || exit 1
cd "$OFFICIAL" && python3 -m scripts.run_loop \
  --eval-set <trigger-evals.json> \
  --skill-path <path-to-skill> \
  --model <this session's model id> \
  --max-iterations 5 --verbose
```

- The **plugin** must be installed; the **skill** may stay disabled — only its
  files are read. `scripts/find-official.sh` resolves the hashed cache path.
- Stdlib only, no `pip install`.
- It writes a temporary command file into `<project-root>/.claude/commands/`, so
  run it from a directory that has a `.claude/`.
- The eval set is ~20 entries of `{"query": …, "should_trigger": true|false}`,
  roughly half each. The negatives that carry information are **near-misses** —
  queries sharing vocabulary with the skill but needing something else. An
  obviously unrelated negative measures nothing.
- Apply `best_description` to the frontmatter, then re-run `scripts/validate.sh`.

---

## Mode 4: Harvest

Applies to skills that have a `_feedback/`. This is what makes the folder worth
having — without harvesting it is a graveyard, which is why it is opt-in rather
than scaffolded by default.

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

## Mode 5: Package

```bash
scripts/package.sh <path-to-skill> [out-dir]
```

Validates first and refuses to package a skill that fails. Copies everything
except `_artifacts/`, `.git/`, and `.DS_Store`. **Keeps `_feedback/`** —
it is the skill's improvement history and should travel with it.

Then scans authored files for absolute home paths and secret-shaped strings and
prints anything it finds. Those are for you to review, not for the script to
decide: read every hit before sharing.

---

## Writing feedback entries

**Only for skills that have a `_feedback/`.** If the running skill has no such
directory, it opted out: there is nothing to write and nothing to create. Do not
add the folder mid-run to hold an entry — raise the friction with the user
instead, and let them decide whether the skill should start recording.

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

**This applies to skill-creator itself**, which does keep a `_feedback/`. If the
user corrects your interview assumptions or your draft description, write the
entry there — regardless of whether the skill you were creating opted in.

---

## Red flags — stop

- About to report a skill as done without running `validate.sh`
- Writing a `description` that describes the procedure rather than the trigger
- Creating `_artifacts/` or `_feedback/` when nothing writes to them
- Scaffolding `_feedback/` without the user having asked for it in the interview
- Leaving a Feedback section in a `SKILL.md` whose skill has no `_feedback/`
- Writing a rule into prose that a regex in `validate.sh` could enforce
- Leaving every mode's detail in the body when a run uses one of them
- Telling the agent to read a whole file when a command could extract the field it needs
- Recommending subagents as a preference instead of a predicate on observable work
- Skipping the interview because the request "seems clear" — it answers at most two of the six questions
- Writing a feedback entry for a run that went fine
- Creating a `_feedback/` directory mid-run just to have somewhere to file an entry
- Harvesting feedback into "improve clarity" instead of a specific edit
- Marking entries resolved without making the edit

## Reference files

| File | Read when |
|---|---|
| `references/spec.md` | Writing or checking any frontmatter |
| `references/conventions.md` | Laying out a directory, choosing where content goes |
| `references/interview.md` | Starting Create mode |
| `references/craft.md` | Writing the body — choosing the form a rule should take |
| `references/economy.md` | Writing the body — deciding what it costs to run, and when a subagent pays |
| `references/feedback-protocol.md` | Writing or harvesting a feedback entry |

## Scripts

| Script | Does |
|---|---|
| `scripts/scaffold.sh <name> [parent] [--artifacts] [--feedback]` | Builds a spec-conformant tree. Validates the name, refuses to overwrite, creates underscore directories only when asked. `--feedback` also seeds `_feedback/README.md`, copies the entry template, and keeps the Feedback section in the generated `SKILL.md`. |
| `scripts/validate.sh <path> [--errors-only]` | Spec + convention checks. Exit 1 on any ERROR. `--errors-only` suppresses WARN and ok lines — used by the SKILL.md edit hook so a clean file stays silent. |
| `scripts/find-official.sh` | Prints the installed official skill-creator's directory, for Tune mode. Exit 1 with install guidance when the plugin is absent. |
| `scripts/package.sh <path> [out]` | Validates, strips runtime output, scans for leaked paths and secrets. |
