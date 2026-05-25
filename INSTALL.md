# Install

This repository exposes Codex and Claude Code plugins named `moos-ivp-skills`.

Codex marketplace metadata lives at `.agents/plugins/marketplace.json`.
Claude Code marketplace metadata lives at `.claude-plugin/marketplace.json`.

## Codex Local Development Install

From any checkout of this repository:

```bash
codex plugin marketplace add /absolute/path/to/moos-ivp-skills
```

Then restart Codex and enable the `MOOS-IvP Skills` plugin if it is not already
enabled.

When changing skills during local development, edit the canonical `skills/`
directory and then run:

```bash
./scripts/sync_codex_plugin.sh
```

This refreshes the self-contained skill copy under
`plugins/codex/moos-ivp-skills/skills`.

## Git Marketplace Install

Once this repository is published and the branch is ready for other users:

```bash
codex plugin marketplace add cbenjamin23/moos-ivp-skills --ref main
```

If the marketplace was already added, update it with:

```bash
codex plugin marketplace upgrade
```

Codex installs plugins into its plugin cache and loads the installed copy. This
repo keeps the Codex plugin package self-contained by copying canonical skills
into the plugin adapter before sharing.

## Validate

Before sharing a checkout or release candidate:

```bash
./scripts/check_plugin_integrity.sh
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  plugins/codex/moos-ivp-skills
claude plugin validate . --strict
claude plugin validate plugins/claude/moos-ivp-skills --strict
```

## Claude Code Local Development Install

From any checkout of this repository:

```bash
claude plugin marketplace add /absolute/path/to/moos-ivp-skills
claude plugin install moos-ivp-skills@moos-ivp-skills
```

When changing skills during local development, edit the canonical `skills/`
directory and then run:

```bash
./scripts/sync_claude_plugin.sh
```

This refreshes the self-contained skill copy under
`plugins/claude/moos-ivp-skills/skills`.
