# Install

This repository exposes Codex and Claude Code plugins named `moos-ivp-skills`.

Codex marketplace metadata lives at `.agents/plugins/marketplace.json`.
Claude Code marketplace metadata lives at `.claude-plugin/marketplace.json`.

## Codex Install

From a local checkout:

```bash
codex plugin marketplace add /absolute/path/to/moos-ivp-skills
codex plugin add moos-ivp-skills@moos-ivp-skills
```

From GitHub:

```bash
codex plugin marketplace add cbenjamin23/moos-ivp-skills --ref main
codex plugin add moos-ivp-skills@moos-ivp-skills
```

To refresh a configured Git marketplace:

```bash
codex plugin marketplace upgrade
```

## Claude Code Install

From a local checkout:

```bash
claude plugin marketplace add /absolute/path/to/moos-ivp-skills
claude plugin install moos-ivp-skills@moos-ivp-skills
```

From GitHub:

```bash
claude plugin marketplace add cbenjamin23/moos-ivp-skills
claude plugin install moos-ivp-skills@moos-ivp-skills
```

## Development Sync

Edit canonical skills under `skills/`, then refresh plugin copies:

```bash
./scripts/sync_codex_plugin.sh
./scripts/sync_claude_plugin.sh
./scripts/check_plugin_integrity.sh
```

## MOOS-IvP Path

Some skills need a local MOOS-IvP checkout for generators, headers, libraries,
and examples. Prefer setting:

```bash
export MOOS_IVP_ROOT=/path/to/moos-ivp
```

You can also give the path directly in the prompt. If neither is provided, the
skills look in the current workspace, nearby folders, and common locations such
as `~/moos-ivp`.

## Validate

Before sharing a checkout or release candidate:

```bash
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  plugins/codex/moos-ivp-skills
claude plugin validate . --strict
claude plugin validate plugins/claude/moos-ivp-skills --strict
./scripts/check_plugin_integrity.sh
```
