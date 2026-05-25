# MOOS-IvP Skills

Portable `SKILL.md` workflows for MOOS-IvP development, mission work, CI harnesses,
documentation lookup, and post-mission analysis.

This repository is intentionally agent-neutral at the top level. The canonical
skill source lives under `skills/`. Product-specific adapters or plugins should
wrap that source rather than become the only copy. The Codex adapter currently
symlinks to the canonical skill tree for local testing.

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

## Validation

Run the repo integrity check before sharing changes:

```bash
./scripts/check_plugin_integrity.sh
```

To validate the Codex plugin manifest with the local plugin creator validator:

```bash
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  plugins/codex/moos-ivp-skills
```

## Distribution Status

This repository is ready for local Codex plugin testing. Before broad public
distribution, decide on a license, replace the development symlink in the Codex
adapter with a self-contained skill copy or release artifact, and confirm the
manifest metadata.
