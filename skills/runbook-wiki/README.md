# runbook-wiki skill

A skill for building and maintaining a **procedural, experience-driven knowledge base** — a runbook or developer survival guide where an AI agent incrementally writes and maintains a structured wiki of solved problems, repeatable procedures, and environment facts. The next person (often future-you, or a teammate) *queries* it instead of re-deriving the fix or asking around.

## What problem this solves

Classic team wikis go stale and you have to scroll and hunt for the right page, so people stop trusting them and the knowledge rots in someone's head. This pattern is different: knowledge **compounds in the repo**. You spend an hour getting the server to build from source, drop three lines into an inbox, and the agent files it into a clean page you can ask about next time. Point any file-capable AI agent at the repo and ask "how do I run tests on Jenkins" — it reads the wiki and answers.

## When to use it

- You want to set up a developer survival guide, runbook, ops/troubleshooting base, or onboarding guide
- You want to file a solved problem or a fix into an existing guide
- You want to query the guide like a chatbot ("how do I set up the dev environment")
- You want a freshness check to surface stale or outdated procedures

## Trigger phrases

- "set up a runbook / developer guide / survival guide"
- "how do I run / build / test / deploy ..."
- "file this fix" / "recurring error"
- "team knowledge base" / "internal tooling guide"
- "check the wiki for stale procedures"

## What it is not

This is for **experience-driven** procedural knowledge — material that comes from *solving problems*, where pages are procedures (symptom → cause → fix, step-by-step how-tos). It is **not** for ingesting and synthesizing source documents (articles, papers, transcripts), and not a bookmark manager or a one-shot research project.

## How it works

Two layers plus optional config: an **inbox** (`raw/inbox/`) for low-friction messy notes the agent clears, and an **agent-maintained wiki** (`wiki/`) of markdown pages, an index, a log, and an overview. Pages default to three types — **how-to**, **troubleshooting**, **reference** — each with `status` + `last-verified` frontmatter so readers know what to trust. The agent owns all the bookkeeping (filing, indexing, cross-linking, flagging staleness); humans solve problems and drop raw notes. It's just a folder of markdown, so git history, PRs, and repo-host rendering come for free.

See [SKILL.md](SKILL.md) for full operational details, page conventions, the freshness-check workflow, and schema design guidance.
