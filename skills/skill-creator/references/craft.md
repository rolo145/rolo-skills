# Writing guidance that actually binds

The spec says what a valid skill looks like. This says what a skill that *works*
looks like. Read during Create mode, after the interview, before writing the body.

## Match the form to the failure

Before writing a rule, classify the failure it targets. The form that fixes one
failure type measurably backfires on another.

| The failure | Right form | Wrong form |
|---|---|---|
| Knows the rule, skips it under pressure | Prohibition + rationalization table + red flags | Soft guidance — "prefer…", "consider…" |
| Complies, but the output has the wrong shape (bloated, buried, restated) | **Positive recipe**: state what the output IS — its parts, in order | Prohibition list — "don't restate", "never narrate" |
| Omits a required element from something they already produce | **Structural**: a REQUIRED field or slot in the template they fill in | Prose reminders near the template |
| Behavior should depend on a condition | **Conditional** on an observable predicate — "if the brief exists, reference it" | Unconditional rule + exemption clauses |

**Why prohibitions backfire on shaping problems.** Given a competing incentive,
an agent negotiates with "don't X" — and a prohibition can produce *more* of the
unwanted content than saying nothing at all. A recipe leaves nothing to negotiate:
the output matches the stated shape or it doesn't.

The second row is the one most often gotten wrong. "Don't write a long summary"
is a prohibition against a shaping failure. "The summary is three sentences: what
changed, what broke, what to do next" is the recipe. Use the recipe.

## Two rules for whichever form you pick

**No nuance clauses.** "Don't X unless it matters" reopens the negotiation you
just closed. Appending one nuance clause to a working rule degrades it from
consistent to noisy. A real exception is its own conditional on an observable
predicate — not a trailing "unless".

**Exemption clauses don't scope.** "This 200-word limit doesn't apply to code
blocks" still suppresses code blocks. If part of the output must be exempt,
restructure so the rule cannot reach it in the first place.

## Keyword coverage

The `description` is matched against what the user typed. Include the words they
would actually use:

- **Error strings** — verbatim: `ENOTEMPTY`, `Hook timed out`, `429 rate limit`
- **Symptoms** — "flaky", "hangs", "never triggers", "silently fails"
- **Synonyms** — timeout/hang/freeze, cleanup/teardown/afterEach
- **Tools and file types** — actual command names, library names, extensions

Describe the *problem*, not one language's symptom of it. "Tests pass and fail
inconsistently" travels; "tests use setTimeout" only matches JavaScript. Make the
skill technology-specific in the trigger only when the skill itself is.

## Examples

One excellent example beats five mediocre ones. Complete, runnable, from a real
scenario, commented to explain *why* — not a fill-in-the-blank template, and not
the same pattern ported to four languages. Pick the language the task actually
lives in.

## Flowcharts

Only for non-obvious decision points, process loops where you'd stop too early,
and "when A vs B" choices. Never for reference material (use a table), code
examples (use a code block), or linear instructions (use a numbered list).

## Content that doesn't belong in a skill

- **Narratives** — "in the October session we discovered…" is not reusable
- **Standard practice documented elsewhere** — link, don't restate
- **Project-specific conventions** — those go in CLAUDE.md/AGENTS.md
- **Anything a regex could enforce** — put it in `validate.sh`, where it exits
  non-zero, instead of in prose, where it gets skipped

## Testing a skill (optional, heavier)

The strongest method is adversarial: run the scenario against a fresh agent
*without* the skill first, record the exact rationalizations it produces, then
write the skill to counter those specific rationalizations and re-run. Wording is
verified with 5+ samples per variant against a no-guidance control — single
samples lie, and variance across runs is itself the signal that a rule isn't
binding.

That method needs subagent dispatch, so it is **not** part of this skill's default
flow. `superpowers:writing-skills` has the full methodology if you want it.

At minimum, before calling a skill done: re-read the `description` cold and ask
whether you would load this skill for the task it targets — and whether you'd
wrongly load it for the neighbouring task the interview identified.
