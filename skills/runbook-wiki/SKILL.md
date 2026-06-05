---
name: runbook-wiki
description: >
  Build and maintain a knowledge base for PROCEDURAL, experience-driven knowledge — things learned
  by doing and fixing, not by reading documents. The unit of knowledge is a solved problem or a
  repeatable procedure (how to run, build, test, deploy, configure, or fix something), captured once
  and reused. Use when the user wants to: set up a developer survival guide, runbook, ops or
  troubleshooting base, or onboarding guide; file a solved problem or fix into one; query one like a
  chatbot ("how do I run tests on Jenkins", "how do I set up the dev environment"); or check it for
  stale procedures. Trigger phrases: "developer guide", "runbook", "how do I run/build/test/deploy",
  "set up the environment", "recurring error", "team knowledge base". Agent-agnostic — needs an agent
  that reads/writes files in a repo. NOT for ingesting and synthesizing source documents (articles,
  papers, transcripts), nor a bookmark manager or one-shot research project.
---

# Runbook Wiki Pattern

A pattern for procedural knowledge bases where an AI agent incrementally writes and maintains a
structured wiki of solved problems, procedures, and environment facts — so the next person (often
future-you, or a teammate) queries it instead of re-deriving the fix or asking around.

This is the **experience-driven** variant of the LLM wiki: material comes from solving problems,
not from ingesting documents. You spend an hour getting the server to build from source, you drop
three lines into the inbox, and the agent files it into a clean page you can ask about next time.

**How this differs from a normal company wiki:** classic wikis go stale and you have to scroll and
hunt for the right page. This one stays clean and you *talk to it* — point any file-capable AI agent
at the repo and ask "how do I run tests on Jenkins"; it reads the wiki and answers. Knowledge
compounds in the repo instead of rotting in someone's head.

**Key idea:** the wiki is a persistent, compounding artifact. The agent does the maintenance —
filing notes, updating the index, flagging stale pages. Humans solve problems and drop raw notes.
The agent is the maintainer; the wiki is the knowledge base; the repo host (or any markdown viewer)
is the reader.

---

## Architecture

**Inbox** (`raw/inbox/`) — low-friction staging for messy, unformatted notes (three lines, a pasted
error, an old guide to import). Not immutable sources — just a queue the agent clears as it files.

**Wiki** (`wiki/`) — the agent-maintained markdown. Page bodies, the index, the log, the overview.
The agent owns this layer: creates pages, files notes into them, keeps the index and cross-links
current, flags what's gone stale.

**Agent config** (`CLAUDE.md` / `AGENTS.md`) — optional. Tells the agent the page types and
conventions for this specific wiki. Optional because a setup block can bake the conventions into the
starter files directly. Keep it domain-specific and agent-agnostic.

---

## Standard files (every wiki)

### `wiki/index.md`
Catalog of every page, one table per page type, with columns `Page | Tags | Status | Last verified`.
The agent reads this first on any query to find relevant pages before drilling in. Updated whenever a
page is added or changed. Fine up to hundreds of pages without any search engine.

### `wiki/log.md`
Append-only chronological record, grep-parseable:

```
## [YYYY-MM-DD] capture | what got filed
## [YYYY-MM-DD] query | question asked
## [YYYY-MM-DD] verify | freshness check
```

### `wiki/overview.md`
What this guide covers and how to use it (which page types exist, how to capture, how to query).
The reader's entry point. Updated only when the big picture changes, not on every capture.

---

## Operations

### Capture & process
Triggered when the user drops notes and says to file them.

1. Read everything in `raw/inbox/`.
2. For each note, decide the page type and whether it extends an existing page or needs a new one.
3. Write/update the page. Procedures are step-by-step and runnable; troubleshooting is symptom → cause → fix.
4. Update `wiki/index.md`.
5. Flag any contradiction with an existing page explicitly on that page.
6. Clear the processed notes from `raw/inbox/`.
7. Append to `wiki/log.md`.

No "discuss takeaways" step — this is procedural, not opinion. Batch is fine here.

### Query
Triggered when the user asks a question against the wiki.

1. Read `wiki/index.md` to find relevant pages.
2. Read them.
3. Answer, citing the specific wiki pages.
4. **Offer to file substantial answers back** — a fix you worked out in chat shouldn't vanish into
   history. Filed answers compound just like captured ones.

The agent may answer in whatever language the user writes in. What gets **written into the repo** is
always the wiki's content language (see conventions).

### Verify (freshness check)
The most important operation for this variant — stale content is the failure mode of every dev wiki.
Run on request, or proactively after a batch of captures.

Check for:
- Pages whose `last-verified` is old, or `status` is `needs-check` / `outdated`.
- Orphan pages (no inbound links).
- Recurring problems that get asked about but have no page yet.
- Unflagged contradictions between pages.
- Procedures superseded by a newer one.
- Secrets/tokens accidentally committed (must never be in the repo).

Output: a prioritized list of issues + suggested fixes.

---

## Page conventions

### Page types
Start with **3**. For a developer/ops guide the default trio is:
- **how-to** — step-by-step procedure for a recurring task.
- **troubleshooting** — symptom/error → cause → fix; found by searching the error, not the task.
- **reference** — stable environment facts: tool versions, repo URLs, service endpoints, config
  locations (never secrets).

Adapt the trio to the domain. A wiki with 3 types and 30 pages beats one with 6 types and 2 pages.

### Frontmatter
```yaml
---
title: Page Title
type: how-to | troubleshooting | reference
tags: [tag1, tag2]
status: verified | needs-check | outdated
last-verified: YYYY-MM-DD
---
```
`status` + `last-verified` are how readers (and the agent) know what to trust. In a shared wiki this
is the difference between a guide people rely on and one they ignore.

### Language
All wiki content — page bodies, headers, frontmatter values, index, log — is written in a single
consistent language, **English by default**. The user may talk to the agent in any language; the
agent answers in that language, but anything written into the repo is always English.

### Linking
Relative markdown links: `[setup](../how-to/dev-environment-setup.md)`. These render natively on
Bitbucket, GitHub, and GitLab. Use `[[wiki-style]]` links *only* if the reader is Obsidian.

### Slugs
Lowercase, hyphenated, no special characters. `run-tests-jenkins.md` not `Run Tests (Jenkins).md`.

### No "My take"
Runbook pages carry no personal-reaction section. A procedure is
right or it's outdated; opinion doesn't belong on it.

### Superseded / abandoned procedures
Never delete a page for an approach that stopped working. Set `status: outdated` and add a
**"Replaced by"** or **"Why dropped"** note. The dead end saves the next person from repeating it.

### Secrets
Never store credentials, tokens, or keys. Reference where they live, not their values.

---

## Capture flow — design principle

The hardest problem is getting material in, especially on a team where everyone is busy. Design
around real behavior, not ideal behavior:

- Keep a `raw/inbox/` staging area for unformatted, low-effort notes. Messy is fine — the agent cleans it up.
- Quick captures are first-class inputs, not draft scraps.
- Minimum viable capture should take under 60 seconds.
- Bootstrap a new wiki by pasting in existing guides once; the agent structures them into pages.

---

## Shared / team notes

- Multiple contributors → trust depends on freshness signals. `status` + `last-verified` is how readers
  know what's reliable. Make the agent surface these on verify.
- It's a git repo → version history, PRs, and blame come for free. Teammates can drop notes into
  `raw/inbox/` or edit pages directly via PR.
- Agent-agnostic: the "process inbox" flow needs an agent that can read and write files in the repo.
  Agents with full repo file access handle it directly; agents without it can still be used for query
  if pointed at the page contents, but won't file notes on their own.

---

## Designing a new wiki schema

When helping the user start one, produce:

**A) Agent config** (`CLAUDE.md` / `AGENTS.md`) — optional. Directory structure, page types with
frontmatter templates, operations, conventions (slugs, linking, status values, language). Domain-specific.

**B) Setup block** — markdown the user pastes to an agent to scaffold the directory tree and starter
files (`index.md`, `log.md`, `overview.md`) with headers only, no content.

Principles:
- Start with 3–4 page types.
- Ask about the user's real habits before designing — a schema built for how someone *wishes* they
  worked gets abandoned.
- Keep the config domain-specific and agent-agnostic. General pattern principles live in this skill.

---

## Tooling (optional)

- **Git** — the wiki is a folder of markdown. History, branching, diffs, PRs for free.
- **Repo host renderer** — Bitbucket / GitHub / GitLab render markdown and relative links natively;
  often that's the only viewer you need.
- **Obsidian** — optional nicer viewer; if used, you can switch to `[[wiki-links]]` and graph view.
- **Markdown search** — `index.md` scanning is enough up to hundreds of pages; add a search tool only
  if it grows beyond that.

Skip anything that doesn't fit the domain — image handling, slide decks, source-ingest steps.

---

## Modular by design

Everything here is optional — take what fits, drop the rest. Small guide? The index file is enough.
No agent config? Bake the conventions into the setup block. The schema co-evolves with the user:
start simple (3 page types, basic frontmatter) and add structure only when the need is real.