# MOOS-IvP Skills

Portable `SKILL.md` workflows for MOOS-IvP development, mission work, CI harnesses,
documentation lookup, and post-mission analysis.

The canonical skill source lives under `skills/`. Codex and Claude Code adapters
carry self-contained copies generated from that source for distribution.

## Skills

- `moos-app-builder` - build or modify user-owned MOOS apps.
- `moos-ivp-behavior-builder` - build or modify user-owned IvP helm behaviors.
- `moos-ivp-docs` - consult upstream MOOS-IvP docs and local source.
- `moos-alog-analysis` - analyze existing `.alog` files with MOOS log tools.
- `moos-ivp-mission-builder` - build ordinary MOOS-IvP mission folders from canonical examples.
- `moos-ivp-eval-mission-builder` - build self-evaluating test missions.
- `moos-ivp-harness-builder` - build multi-case harnesses and regression suites, including `nspatch` variants.

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

For install commands, see `INSTALL.md`.

## Repository Layout

```text
skills/                 Canonical, agent-neutral skill folders.
plugins/<product>/...    Product adapters around the skills.
.agents/plugins/        Codex marketplace metadata.
.claude-plugin/         Claude Code marketplace metadata.
scripts/                Setup, validation, and packaging helpers.
docs/                   Distribution notes.
test-runs/              Ignored local validation output, not distribution source.
```

See `docs/distribution-adapters.md` for Codex and Claude Code distribution
notes.

## Validation

After editing canonical skills, refresh both plugin copies:

```bash
./scripts/sync_codex_plugin.sh
./scripts/sync_claude_plugin.sh
./scripts/check_plugin_integrity.sh
```

Direct validators:

```bash
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  plugins/codex/moos-ivp-skills
claude plugin validate . --strict
claude plugin validate plugins/claude/moos-ivp-skills --strict
```

## Distribution Status

This public GitHub repository is distributable as both a Codex marketplace and a
Claude Code marketplace. Scratch installs from the GitHub URL have been
validated for both adapters at `v1.0.0`.
