# MOOS-IvP Skills

Portable `SKILL.md` workflows for MOOS-IvP development, mission work, CI harnesses,
documentation lookup, and post-mission analysis.

This repository is intentionally agent-neutral at the top level. The canonical
skill source lives under `skills/`. Product-specific adapters or plugins should
wrap that source rather than become the only copy. The Codex adapter carries a
self-contained copy generated from the canonical skill tree for distribution.

## Skills

- `moos-app-builder` - build or modify user-owned MOOS apps.
- `moos-ivp-behavior-builder` - build or modify user-owned IvP helm behaviors.
- `moos-ivp-docs` - consult upstream MOOS-IvP docs and local source.
- `moos-alog-analysis` - analyze existing `.alog` files with MOOS log tools.
- `moos-ivp-mission-builder` - build ordinary MOOS-IvP mission folders from canonical examples.
- `moos-ivp-eval-mission-builder` - build self-evaluating test missions.
- `moos-ivp-harness-builder` - build multi-case harnesses and regression suites, including `nspatch` variants.

## Codex Plugin

The Codex plugin adapter lives at `plugins/codex/moos-ivp-skills/`.

Its manifest is `plugins/codex/moos-ivp-skills/.codex-plugin/plugin.json`.
The repo marketplace is `.agents/plugins/marketplace.json`.

For install and testing notes, see `INSTALL.md`.

## Repository Layout

```text
skills/                 Canonical, agent-neutral skill folders.
plugins/<product>/...    Product adapters around the skills.
.agents/plugins/        Agent marketplace metadata for this repo.
config/                 Example local MOOS environment config.
scripts/                Setup, validation, and packaging helpers.
docs/                   Design notes for skill boundaries and setup.
test-runs/              Ignored local validation output, not distribution source.
```

See `docs/distribution-adapters.md` for Codex and Claude Code distribution
notes.

## Validation

Run the repo integrity check before sharing changes:

```bash
./scripts/check_plugin_integrity.sh
```

After editing canonical skills, sync the Codex plugin copy:

```bash
./scripts/sync_codex_plugin.sh
```

To sync and validate the Claude Code plugin copy:

```bash
./scripts/sync_claude_plugin.sh
```

To validate the Codex plugin manifest with the local plugin creator validator:

```bash
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  plugins/codex/moos-ivp-skills
```

## Distribution Status

This repository is Codex-distributable from the repo marketplace. Canonical
skills remain under `skills/`; the Codex plugin copy is refreshed with
`scripts/sync_codex_plugin.sh`.
