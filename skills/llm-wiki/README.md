# llm-wiki skill

A skill for building and maintaining a **persistent personal knowledge base** where the LLM writes and maintains a structured wiki of markdown files — rather than re-deriving knowledge from raw sources on every query.

## What problem this solves

Most RAG setups (NotebookLM, ChatGPT file uploads) re-derive knowledge from scratch on every question. Nothing accumulates. This pattern is different: the LLM **incrementally builds a wiki** that sits between you and your raw sources. Cross-references, contradictions, and synthesis are compiled once and kept current. The wiki gets richer with every source you add and every question you ask.

## When to use it

- You want to set up a new wiki for a domain (research, reading, self-tracking, business intel)
- You want to ingest a source into an existing wiki
- You want to query across accumulated knowledge
- You want a health check on an existing wiki
- You're thinking about Obsidian + LLM workflows or personal knowledge management

## Trigger phrases

- "set up a wiki for [domain]"
- "process this source into my wiki"
- "what does my wiki say about X"
- "health check the wiki"
- "I want to accumulate knowledge about X over time"

## How it works

Three layers: **raw sources** (immutable, LLM reads only), **wiki** (LLM-owned markdown files), and a **schema** (`CLAUDE.md` / `AGENTS.md`) that configures the LLM as a disciplined wiki maintainer for your specific domain.

The LLM handles all the bookkeeping — summarizing, cross-referencing, filing, updating. You handle sourcing, direction, and questions. Obsidian is a good viewer (graph view, Dataview, Marp).

See [SKILL.md](SKILL.md) for full operational details, page conventions, and schema design guidance.
