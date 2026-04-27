---
name: llm-wiki
description: >
  Pattern for building and maintaining a persistent personal knowledge base (wiki) using an LLM.
  Use this skill whenever the user wants to set up a new wiki, ingest a source into an existing wiki,
  query a wiki, lint/health-check a wiki, or design a CLAUDE.md schema for a new domain.
  Also trigger when the user mentions Obsidian + LLM workflows, personal knowledge bases,
  or asks how to accumulate knowledge across sessions rather than re-deriving it each time.
  Good fits: research wikis, reading companions, self-tracking, business/team intel, competitive
  analysis, due diligence, course notes, trip planning, any domain where knowledge accumulates over time.
---

# LLM Wiki Pattern

A pattern for building personal knowledge bases where the LLM incrementally writes and maintains
a structured wiki of markdown files — rather than re-deriving knowledge from raw sources on every query.

**How this differs from RAG:** Most LLM + document setups (file uploads, NotebookLM, ChatGPT RAG)
re-derive answers from raw sources on every query — nothing accumulates. This pattern is different:
the LLM builds a persistent wiki that sits between the user and raw sources. Cross-references,
contradictions, and synthesis are compiled once and kept current. Ask a question that requires
synthesizing five documents, and the answer is already partly there — not reconstructed from scratch.

**Key idea:** The wiki is a persistent, compounding artifact. Cross-references, contradictions, and
synthesis are compiled once and kept current. The LLM does all the maintenance; the human curates,
directs, and asks questions. The LLM is the programmer; the wiki is the codebase; Obsidian (or any
markdown viewer) is the IDE.

---

## Architecture — three layers

**Raw sources** (`raw/`) — immutable source documents. Articles, papers, transcripts, images, data files.
The LLM reads from here but never modifies anything. This is the source of truth.

**Wiki** (`wiki/`) — LLM-generated markdown files. Summaries, entity pages, concept pages, comparisons,
overview, synthesis. The LLM owns this layer entirely: creates pages, updates them on every ingest,
maintains cross-references, keeps everything consistent.

**Schema** (`CLAUDE.md` / `AGENTS.md`) — tells the LLM how this specific wiki is structured,
what the page types and conventions are, and what workflows to follow. Domain-specific config.
The general pattern lives in this skill; the domain-specific config lives in the schema file.

---

## Standard files (every wiki)

### `wiki/index.md`
Content-oriented catalog. Every wiki page listed with a link and a one-line summary, organized by
category. The LLM reads this first when answering any query to find relevant pages before drilling in.
Updated on every ingest. Works well up to ~hundreds of pages without needing vector search.

### `wiki/log.md`
Append-only chronological record of all operations. Format each entry consistently:

```
## [YYYY-MM-DD] ingest | Source Title
## [YYYY-MM-DD] query | Question asked
## [YYYY-MM-DD] lint | Health check
```

Consistent prefix makes it grep-parseable: `grep "^## \[" log.md | tail -5`

### `wiki/overview.md`
Running synthesis of the whole wiki. Updated periodically (not on every ingest — only when something
meaningfully changes the big picture). The human's best entry point to the current state of knowledge.

---

## Operations

### Ingest
Triggered when the user drops a new source and says to process it.

Default flow:
1. Read the source
2. Discuss key takeaways with the user (don't skip this — the human's reaction matters)
3. Write a source summary page in `wiki/sources/`
4. Update `wiki/index.md`
5. Update relevant entity/concept pages across the wiki (a single source may touch 10–15 pages)
6. Note any contradictions with existing content explicitly on the affected pages
7. Append to `wiki/log.md`

Prefer one source at a time with human in the loop. Batch ingestion is possible but loses the
discussion step, which is where the human's perspective gets captured.

### Query
Triggered when the user asks a question against the wiki.

Flow:
1. Read `wiki/index.md` to identify relevant pages
2. Read the relevant pages
3. Synthesize an answer with citations to specific wiki pages (not raw sources)
4. **Always offer to file substantial answers back into the wiki** (comparisons, analyses, discovered
   connections). Good answers shouldn't disappear into chat history — filed answers compound in the
   knowledge base just like ingested sources do. This is a key differentiator of the pattern.

Output formats depending on question type: markdown page, comparison table, Marp slide deck,
chart, structured list. Match the format to the question.

### Lint
Periodic health check. Run when the user asks, or proactively suggest it after every ~10 ingests.

Check for:
- Orphan pages (no inbound links from other wiki pages)
- Important concepts mentioned across pages but lacking their own page
- Contradictions between pages that haven't been flagged
- Stale claims that newer sources have superseded
- Missing cross-references between related pages
- Data gaps: things the wiki doesn't know that could be filled with a web search or a new source

Output: a prioritized list of issues + suggested fixes + suggested new sources to find.

### Weekly synthesis (optional)
Look across everything added in the past week. Surface: patterns, contradictions, connections the
human hasn't noticed, open questions worth pursuing. File the result as a dated synthesis page.

---

## Page conventions

### Frontmatter (recommended)
```yaml
---
title: Page Title
type: source | entity | concept | synthesis | query
date: YYYY-MM-DD
sources: 3          # number of sources this page draws from
tags: [tag1, tag2]
status: current | stale | stub
---
```

### Linking style
Always use wiki-style links: `[[page-slug]]`. Never bare URLs inside the wiki — link to source
summary pages instead, which then reference the original URL.

### Slugs
Lowercase, hyphenated, no special characters. `openai-gpt4o` not `OpenAI GPT-4o`.

### The human's take
Every source summary page and entity page should have a **"My take"** or equivalent section near
the top. Summaries without personal reaction are just worse documentation. If the human hasn't
given a reaction yet, leave the section as a stub — don't fill it in from the source.

### Abandoned / rejected entries
Never delete pages for things that didn't work out (tools, rejected hypotheses, dropped ideas).
Add `status: rejected` to frontmatter and a **"Why dropped"** section. The reasoning is often
more useful than the thing itself.

---

## Capture flow — design principle

The hardest problem is getting raw material in. Design the capture flow around the user's real
constraints, not ideal behavior:

- Always include a `raw/quick-captures/` staging area for unformatted, low-effort inputs
  (a link, a voice memo transcript, 3 lines of text). The LLM processes these into proper pages.
- Quick captures are first-class inputs — not second-class drafts.
- The minimum viable capture should take under 60 seconds.

---

## Designing a new wiki schema (CLAUDE.md)

When helping the user start a new wiki, produce:

**A) `CLAUDE.md`** — the schema the user drops into the repo root. Must include:
- Directory structure
- Page types with frontmatter templates and required sections (3–4 types max to start)
- Operations: ingest, query, lint, any domain-specific workflows
- Conventions: slugs, linking style, status values, tone
- Behavior instructions specific to this domain

**B) Setup block** — markdown the user pastes to Claude Code to scaffold the directory structure
and starter files (`index.md`, `log.md`, `overview.md` with headers only).

Schema design principles:
- Start with 3–4 page types. A wiki with 2 types and 30 pages beats one with 6 types and 2 pages.
- Keep `CLAUDE.md` domain-specific. General pattern principles live in this skill — don't repeat them.
- Ask about the user's real habits before designing. A schema built for how someone wishes they
  worked will be abandoned.

---

## Tooling (optional)

**Obsidian** — best viewer for a markdown wiki. Graph view shows the shape of the knowledge base
(hubs, orphans, clusters). Marp plugin renders slide decks from wiki content.

**Dataview** (Obsidian plugin) — runs queries over page frontmatter. If the LLM adds YAML frontmatter
(tags, dates, source counts), Dataview generates dynamic tables and lists automatically.

**Obsidian Web Clipper** — browser extension that clips articles to markdown. Fast source capture.

**qmd** — local search engine for markdown with BM25/vector hybrid search and LLM re-ranking.
CLI + MCP server. Useful when the wiki grows beyond ~200 pages and `index.md` scanning gets slow.
Repo: https://github.com/tobi/qmd

**Git** — the wiki is just a folder of markdown files. Version history, branching, and diffing for free.

**Images** — LLMs can't read markdown with inline images in one pass. Workaround: read text first,
then view referenced images separately. Download images locally (Obsidian hotkey: Ctrl+Shift+D after
setting attachment folder path in settings) so URLs don't rot.

---

## Modular by design

Everything in this skill is optional. Pick what fits your domain and drop the rest:
- Small wiki? The index file is enough — no search engine needed.
- Text-only sources? Skip image handling entirely.
- Not using Obsidian? Any markdown editor works.
- Don't need slide decks? Ignore Marp.

The schema (`CLAUDE.md`) is also not a one-shot artifact — co-evolve it with the user as you
discover what conventions work for their domain. Start simple (3 page types, basic frontmatter)
and add structure only when the need is real.