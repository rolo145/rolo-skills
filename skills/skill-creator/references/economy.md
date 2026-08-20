# Context economy

Every skill is paid for by someone. This is where the bill lands, and which
levers actually move it. Read during Create mode, alongside `craft.md` — the two
pull in opposite directions and the tension is the point: `craft.md` makes a rule
bind, this file makes it cheap. A rule compressed until it stops binding costs a
whole wrong run, which is far more than the tokens it saved.

## Who pays for what

| Tier | Paid | Charged to |
|---|---|---|
| `description` | Every conversation, whether or not the skill ever runs | Every user, always |
| `SKILL.md` body | Every activation | Every run |
| `references/*`, script *source* | Only when actually read | Only the runs that need it |
| Script *output* | When it runs | The run — usually 10–100× smaller than its source |

Two consequences fall straight out of that table.

The `description` is the highest-leverage text in the whole skill: it is the only
part billed to people who never use the skill. Spend the effort there.

The last row is the whole game. A 200-line script that prints five lines of
verdict costs five lines. The same rule written as prose in the body costs its
full length on every activation — and gets skipped some of the time anyway.

## Levers, strongest first

**1. Push mode-specific detail below the fold.** The useful question is not "is
the body under 500 lines" but *what fraction of it does a typical run use?* A
four-mode skill carrying all four modes' detail in the body wastes three
quarters of it every time. Keep the routing table in the body; move each mode's
detail into `references/<mode>.md`.

**2. Let a script decide and print the verdict.** Its source is never loaded, and
it cannot be skipped. Prose is loaded always and obeyed sometimes.

**3. Hand the agent a predicate, not a file to read.** "If the branch has no
upstream" is free to evaluate. "Read the config and decide" costs the config.

**4. Name the cheap command.** `grep -c`, `head -50`, `git diff --stat`,
`jq -r '.field'`, `sed -n '40,80p'` — not `cat` of a 2000-line file whose one
interesting field you already know. Reading whole files to check one thing is the
most common waste in practice, and naming the command is how a skill prevents it.

**5. Dispatch a subagent to keep bulk output out of the caller's context.** See
below — this one has a real trade-off and gets stated wrong most often.

## The subagent trade, honestly

A subagent is **not** cheaper in total. It pays for its own context, its own
reasoning, and its report. What it buys is that the intermediate output never
enters the calling conversation.

Dispatch one when the work generates a lot of output nobody needs to keep — a
sweep across many files, a long build log, a broad search — **and** the
conclusion is small. The longer the calling conversation already is, the more
that protection is worth.

Do not dispatch one when you already know the file and the symbol (read it
directly); when the bulk *is* the deliverable and the caller needs all of it
anyway; or when the subagent would need so much context to start that you pay for
the dump twice.

Write it into a skill as a predicate, never a preference. "If the search spans
more than one directory, dispatch a subagent and ask only for the conclusion"
binds. "Consider using subagents where appropriate" does not.

## Anti-patterns

| Pattern | What it costs | Instead |
|---|---|---|
| Every mode's detail inline in the body | Paid on every run, used one mode's worth | Routing table in the body, detail in `references/<mode>.md` |
| "Read the file and check X" | The whole file | Name the command that extracts X |
| A rule stated in prose *and* enforced by a script | Both | Script only, plus one line pointing at it |
| Background / philosophy / history sections | Every activation, changes no decision | Cut it. If it changes no action, it is not instruction. |
| The same guidance ported to four languages | 4× | One excellent example, in the language the task lives in |
| Loading a reference "for context" up front | The whole file, often unused | Read it at the decision it serves, not before |
| A reference split so fine that one question needs three files | Three round trips | One focused file per question |

## Measuring instead of guessing

    wc -l SKILL.md references/*.md          # what a run pays, worst case
    scripts/validate.sh <skill>             # flags a large body with nothing below it

For the `description`, guessing is not available: it fails silently, and re-reading
your own words tells you nothing. Use the **Tune** mode in `SKILL.md`, which
measures trigger rate directly.
