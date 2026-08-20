# Interview protocol (Create mode)

A skill lives or dies on its `description`, and nobody can write a good one from
a one-line request. The interview exists to produce a description precise enough
to trigger correctly, and a body scoped tightly enough to be worth loading.

## The six questions

| # | Ask | Determines |
|---|---|---|
| 1 | When should this fire? What would the user actually type? | The "when" half of `description` |
| 2 | When should it *not* fire? What is the nearest thing this isn't? | Boundaries — stops over-triggering |
| 3 | What does a successful run produce? | Body structure; whether `_artifacts/` is needed |
| 4 | Fixed procedure, or judgment guidance? | `scripts/` vs `references/` split |
| 5 | What tools, CLIs, or access must exist? | `compatibility`, `allowed-tools` |
| 6 | What goes wrong when a human does this task today? | Red-flags table; seeds the feedback triggers |

Question 2 is the one most often skipped and most often responsible for a bad
skill. A skill that fires on everything adjacent is worse than one that never
fires, because it displaces the right skill.

Question 6 is where the skill's real content usually comes from. "What goes
wrong" is the reason the skill needs to exist; a skill that only describes the
happy path teaches nothing the agent didn't already know.

## Three rules

**Infer first, ask only the gaps.** If the request already says "for updating npm
dependencies via the dep-guard CLI", questions 1 and 5 are answered. Asking them
back reads as not having listened. Never ask a question the request already
answers.

**Batch, don't interrogate.** Use `AskUserQuestion` with concrete multiple-choice
options and a stated recommendation. At most two rounds of up to four questions.
Six sequential messages is an interrogation, and the user starts answering
carelessly by the fourth.

**Confirm before writing files.** End the interview by echoing back:

1. A one-paragraph brief of what the skill will do
2. The **draft `description` verbatim**
3. The directory layout you intend to create

Then stop for a yes or no. The description is the cheapest field to get wrong and
the most expensive to notice later: it fails *silently*, by the skill simply
never loading, and nothing in any transcript tells you it happened.

## When the user corrects you

A correction at the confirmation step means the interview missed something. Write
a `_feedback/` entry against skill-creator itself with `trigger: user-correction`,
recording which of the six questions should have caught it.

That is the loop closing on its own tail: this skill installs the feedback
protocol into every skill it creates, and is subject to it too.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Asking all six regardless of what the request said | Reads as a form; user disengages |
| Open-ended questions with no options | Costs the user more effort than writing the skill themselves |
| Writing files before confirming the description | The one field you cannot cheaply fix later |
| Accepting "it should handle everything" for Q2 | No boundary means it over-triggers; push for the nearest neighbour it isn't |
