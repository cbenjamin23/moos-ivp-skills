# MOOS-IvP Skills

Portable `SKILL.md` workflows for MOOS-IvP development, mission work, test harnesses,
documentation lookup, and post-mission analysis.

The canonical skill source lives under `skills/`. Codex and Claude Code adapters
carry self-contained copies generated from that source for distribution.

## Skills

- `moos-app-builder` - build or modify user-owned MOOS apps.
- `ivp-behavior-builder` - build or modify user-owned IvP helm behaviors.
- `moos-ivp-docs` - consult upstream MOOS-IvP docs and local source.
- `moos-alog-analysis` - analyze existing `.alog` files with MOOS log tools.
- `moos-ivp-mission-builder` - build ordinary MOOS-IvP mission folders from canonical examples.
- `moos-ivp-eval-mission-builder` - build self-evaluating test missions.
- `moos-ivp-harness-builder` - build multi-case test harnesses, including `nspatch` variants.

## Plugins

This repo is both the maintainer workspace and the marketplace source. Only the
adapter directories below are installed as plugins; root-level docs and scripts
are for maintaining and validating the release.

Codex:

```text
.agents/plugins/marketplace.json
plugins/codex/moos-ivp-skills/
```

Claude Code:

```text
.claude-plugin/marketplace.json
plugins/claude/moos-ivp-skills/
```

Other agent harnesses that support skill-style instructions can usually use the
canonical `skills/` directory directly. If your harness is not Codex or Claude
Code, ask your agent to copy or load the skill folders from `skills/` into the
location its harness expects.

For install commands, see `INSTALL.md`.

## Repository Layout

```text
skills/                  Canonical, agent-neutral skill folders.
plugins/codex/...        Codex plugin adapter.
plugins/claude/...       Claude Code plugin adapter.
INSTALL.md               Install commands and MOOS-IvP path setup.
docs/                    Maintainer distribution notes.
scripts/                 Maintainer sync, validation, and release helpers.
```
