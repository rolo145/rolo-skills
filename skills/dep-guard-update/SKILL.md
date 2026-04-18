---
name: dep-guard-update
description: Use when user explicitly asks to update npm dependencies, analyze dependency risks, check package changelogs, or run dep-guard security checks. Covers both interactive install and risk-analysis-only modes.
---

# dep-guard Update Workflow

Two modes for working with npm dependency updates via the dep-guard CLI.

## Which Mode?

| User says… | Mode |
|---|---|
| "update my deps", "install updates", "run dep-guard update" | **Mode 1** — Interactive update |
| "analyze risks", "check changelogs", "what's risky to update" | **Mode 2** — Risk analysis only |

---

## Mode 1: Interactive Update

### Step 1 — Discover available updates

```bash
dep-guard update --dry-run --json
```

Parse `updates[]`. If empty, tell user and stop.

Present as numbered list:
```
Available updates:
  1. lodash       4.17.20 → 4.17.21  (patch)
  2. chalk        4.1.0   → 5.3.0    (major)
  3. typescript   5.0.0   → 5.4.2    (minor)
```

Ask: "Which packages do you want to update? (numbers, ranges, or 'all')"

### Step 2 — NPQ security check

Run for each selected package:
```bash
dep-guard npq <name@version> --json
```

Collect all results, then present a **summary**:

- **Auto-approved** — `passed: true` OR `requiresUserDecision: false` → list as ✓, no prompt
- **Needs review** — `requiresUserDecision: true` → show issues with plain-language analysis

For each package needing review, explain:
- What each issue means in plain language
- Risk level (low / medium / high)
- Common/expected warning vs genuine red flag

Ask per-package: "Install [package]? (yes/skip)"

Rejected packages are removed. If none remain, stop.

### Step 3 — Install via SCFW

```bash
dep-guard scfw <pkg1@ver1> <pkg2@ver2> ... --json
```

If `success: false`:
- Explain what the error means in plain language (supply chain block, version too new, network issue, etc.)
- Ask: "Is this a red flag that means we shouldn't install this package, or is it something we can ignore?"

If **red flag**: remove the package from the list, continue installing the remaining packages.

If **ignorable**: note the risk, skip the package for now, and let the user decide whether to investigate further.

### Step 4 — Quality checks

Ask: "Run quality checks? (yes/no)"

If yes, ask which: `lint` / `typecheck` / `test` / `build`

`dep-guard quality` runs **all checks that have a matching npm script** — it cannot run a subset. If user wants only some checks, note which ones they care about and flag results for the rest as informational.

```bash
dep-guard quality --json
```

Explain each failed check and suggest next steps.

---

## Mode 2: Risk Analysis

### Step 1 — Get available updates

```bash
dep-guard update --dry-run --json
```

### Step 2 — Research each package

For each update (use parallel subagents if many packages):

1. Fetch changelog / release notes from GitHub releases or the npm page
2. Identify: breaking changes, security fixes, deprecations, API surface changes

### Step 3 — Present risk report

**🔴 High** — major version with breaking changes, known advisories, large API changes

**🟡 Medium** — minor version with deprecations or behavioral shifts

**🟢 Low** — patch versions, bug fixes, no API changes

For each package: what changed, what to watch in the codebase, migration steps if any.

End with: "Want to proceed with any of these? I can run the interactive update flow."

---

## Key Rules

- Always use `--json` — parse structured output, never screen-scrape
- `requiresUserDecision: false` → proceed silently, no prompt needed
- `requiresUserDecision: true` → show analysis, wait for explicit approval
- Rejected packages are skipped — never abort the whole run for one rejection
- Never invent dep-guard flags — only use flags shown above

## Common Mistakes

| Mistake | Fix |
|---|---|
| Prompting user for allowlisted packages | Check `requiresUserDecision` first — if false, continue silently |
| Aborting when one package is rejected | Remove it from the list, continue with the rest |
| Expecting `dep-guard quality` to run only selected checks | It runs all checks with scripts; present all results, flag the ones user cares about |
| Passing custom script names as check selectors | `--lint <name>` renames the script, it doesn't enable/disable lint |
