# Layout conventions

Extends the agentskills.io spec. The spec defines `scripts/`, `references/`, and
`assets/`; it says nothing about where a running skill puts what it produces.
Without a rule, run output lands next to source files and the directory stops
being readable.

## The rule

**Unprefixed directories are the skill. Underscore-prefixed directories are what
it produced.**

```
my-skill/
├── SKILL.md          # the skill
├── scripts/          # the skill
├── references/       # the skill
├── assets/           # the skill
├── _artifacts/       # produced
├── _feedback/        # produced
└── _memory/          # produced
```

One glance separates authored content from runtime exhaust. So does one
`.gitignore` line. So does a packaging script.

## Directory semantics

| Directory | Holds | Lifetime | Git |
|---|---|---|---|
| `scripts/` | Executable code the skill runs | Authored | committed |
| `references/` | Docs loaded on demand | Authored | committed |
| `assets/` | Templates, schemas, images | Authored | committed |
| `_artifacts/` | Output of runs — reports, generated files | Disposable | **ignored** |
| `_feedback/` | Friction notes for later improvement | Cumulative | **committed** |
| `_memory/` | State carried between runs | Machine-local | **ignored** |

`_feedback/` is committed on purpose. It is small, it is the skill's improvement
history, and it must travel with the skill when shared — a skill that arrives
without its known rough edges arrives incomplete.

`_artifacts/` and `_memory/` are ignored because they are per-run and
per-machine. Committing them creates conflicts and leaks local paths.

## Only create what gets written

An empty `_artifacts/` in a skill that produces no files is noise pretending to
be convention. Create an underscore directory only when the skill has a
mechanism that writes to it.

`_feedback/` is the exception: create it always, because every skill can hit
friction. Seed it with a `README.md` so the directory survives git and documents
itself.

## Where content goes

| Content | Location | Why |
|---|---|---|
| The procedure, decision rules, red flags | `SKILL.md` inline | Needed whenever the skill is active |
| Reference over ~100 lines | `references/<topic>.md` | Costs context only when actually consulted |
| A rule checkable by regex | `scripts/validate.sh` | Enforcement beats documentation; prose rules get skipped, scripts exit non-zero |
| Templates the skill fills in | `assets/` | Keeps the body short and the format in one place |

The third row is the one most often gotten wrong. If you catch yourself writing
"remember to check that X matches Y", write the check instead.

## Naming

Directory name and the `name` field must match exactly — the spec requires it and
`validate.sh` enforces it.

Prefer verb-first, active names for skills that describe a process
(`creating-skills`, `reviewing-diffs`) over nominalizations
(`skill-creation`, `diff-review`). Name by what you do, or by the core insight.

## .gitignore

Every skill gets one, from `assets/gitignore.template`:

```
_artifacts/
_memory/
.DS_Store
```

`_feedback/` is deliberately absent from that list.
