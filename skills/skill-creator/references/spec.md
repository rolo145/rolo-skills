# agentskills.io specification — condensed

Source: https://agentskills.io/specification

## Minimum

A skill is a directory containing at minimum a `SKILL.md` with YAML frontmatter
followed by Markdown body.

## Frontmatter fields

| Field | Required | Constraint |
|---|---|---|
| `name` | yes | 1–64 chars. Lowercase `a-z`, `0-9`, `-` only. No leading/trailing hyphen. No consecutive `--`. Must equal the parent directory name. |
| `description` | yes | 1–1024 chars, non-empty. What it does AND when to use it. |
| `license` | no | License name, or the name of a bundled license file. Keep short. |
| `compatibility` | no | 1–500 chars. Environment requirements only. Most skills omit it. |
| `metadata` | no | Map of string keys to string values. Namespace your keys to avoid collisions. |
| `allowed-tools` | no | Space-separated pre-approved tools, e.g. `Bash(git:*) Bash(jq:*) Read`. Experimental; support varies by agent. |

`name` regex: `^[a-z0-9]+(-[a-z0-9]+)*$` — this single pattern enforces the
character set, both hyphen-position rules, and the no-consecutive-hyphen rule.

Note `metadata` values must be strings. `version: 1.0` parses as a float in YAML;
write `version: "1.0"`.

## Valid / invalid names

```yaml
name: pdf-processing      # valid
name: data-analysis       # valid
name: PDF-Processing      # INVALID — uppercase
name: -pdf                # INVALID — leading hyphen
name: pdf--processing     # INVALID — consecutive hyphens
```

## Body

No format restrictions. Recommended: step-by-step instructions, input/output
examples, edge cases.

The entire body loads once the skill activates, so length is a real cost.
Keep `SKILL.md` under 500 lines and push detail into referenced files.

## Conventional directories

| Directory | Holds |
|---|---|
| `scripts/` | Executable code. Self-contained or with documented dependencies; helpful error messages; handles edge cases. |
| `references/` | Docs loaded on demand — `REFERENCE.md`, `FORMS.md`, domain files. Keep each focused; smaller files cost less context. |
| `assets/` | Templates, images, data files, schemas. |

Any additional files and directories are permitted.

## Progressive disclosure

Three tiers, each loaded only when needed:

| Tier | Loaded | Budget |
|---|---|---|
| Metadata — `name` + `description` | At startup, for every skill | ~100 tokens |
| Instructions — full `SKILL.md` body | On activation | <5000 tokens recommended |
| Resources — `scripts/`, `references/`, `assets/` | On demand | unbounded |

The `description` is the only part paid for in every conversation. It is the
highest-leverage field in the file.

## File references

Use paths relative to the skill root:

```markdown
See [the reference guide](references/REFERENCE.md) for details.
Run the extraction script: scripts/extract.py
```

Keep references one level deep from `SKILL.md`. Avoid nested reference chains
(a reference that points at another reference that points at a third).

## Validation

The reference implementation is `skills-ref`:

```bash
skills-ref validate ./my-skill
```

Source: https://github.com/agentskills/agentskills/tree/main/skills-ref

`scripts/validate.sh` in this skill covers the same frontmatter rules without
requiring the CLI, and adds the underscore-prefix convention checks. It invokes
`skills-ref` as well when it is on PATH.
