# MOOS-IvP Skills

Portable `SKILL.md` workflows for MOOS-IvP development, mission work, CI harnesses,
documentation lookup, and post-mission analysis.

This repository is intentionally agent-neutral at the top level. The canonical
skill source lives under `skills/`. Product-specific adapters or plugins should
wrap that source rather than become the only copy; the Codex adapter symlinks to
the canonical skill tree for local testing.

## Planned Skills

- `moos-app-builder` - build or modify user-owned MOOS apps.
- `moos-ivp-behavior-builder` - build or modify user-owned IvP helm behaviors.
- `moos-ivp-docs` - consult upstream MOOS-IvP docs and local source.
- `moos-alog-analysis` - analyze existing `.alog` files with MOOS log tools.
- `moos-ivp-mission-builder` - build ordinary MOOS-IvP mission folders from canonical examples.
- `moos-ivp-eval-mission-builder` - build self-evaluating test missions.
- `moos-ivp-harness-builder` - build multi-case harnesses and regression suites, including `nspatch` variants.

## Repository Layout

```text
skills/                 Canonical, agent-neutral skill folders.
plugins/<product>/...    Product adapters around the skills.
.agents/plugins/        Agent marketplace metadata for this repo.
config/                 Example local MOOS environment config.
scripts/                Setup, validation, and packaging helpers.
docs/                   Design notes for skill boundaries and migration.
test-runs/              Ignored local validation output, not distribution source.
```

## Status

This scaffold is a starting point. The next work is to continue splitting the
current local CI/CD skill into focused, portable skills with references and
validation scripts.
