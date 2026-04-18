# rolo-skills

AI coding assistant skills for Claude Code, Codex CLI, and GitHub Copilot.

## Skills

| Skill | Description |
|---|---|
| [dep-guard-update](skills/dep-guard-update/SKILL.md) | npm dependency updates via dep-guard CLI |

## Installation

**Note:** Installation differs by platform.

### Claude Code — Marketplace

Register the marketplace first:

```
/plugin marketplace add rolo145/rolo-skills
```

Then install:

```
/plugin install rolo-skills@rolo-skills
```

### Claude Code — Direct install

```bash
claude plugin install rolo145/rolo-skills
```

### Any agent (via npx skills)

```bash
npx skills add rolo145/rolo-skills
```

### OpenAI Codex CLI (manual)

```bash
git clone https://github.com/rolo145/rolo-skills.git ~/.codex/rolo-skills
mkdir -p ~/.agents/skills
ln -s ~/.codex/rolo-skills/skills ~/.agents/skills/rolo-skills
```

Restart Codex to discover the skills.

### GitHub Copilot

Copy the relevant `SKILL.md` content into `.github/copilot-instructions.md` in the target project.
