# Install

This repo publishes a Codex and Claude Code plugin named `moos-ivp-skills`.
The easiest path is to add this GitHub repository as a plugin marketplace:

```text
https://github.com/cbenjamin23/moos-ivp-skills
```

In the Codex or Claude Code GUI, add that link as a plugin marketplace and
install `moos-ivp-skills`. You can also ask the agent to install the plugin from
the link.

## CLI Install

Codex:

```bash
codex plugin marketplace add https://github.com/cbenjamin23/moos-ivp-skills
codex plugin add moos-ivp-skills@moos-ivp-skills
```

Claude Code:

```bash
claude plugin marketplace add https://github.com/cbenjamin23/moos-ivp-skills
claude plugin install moos-ivp-skills@moos-ivp-skills
```

For a local checkout, replace the GitHub URL with
`/absolute/path/to/moos-ivp-skills`. To refresh an already configured Codex Git
marketplace:

```bash
codex plugin marketplace upgrade
```

## Other Agents

If your agent does not use Codex or Claude Code plugins, use the canonical
`skills/` directory directly. Copy or load the skill folders from `skills/` into
the location your harness expects for skill-style instructions.

## What Gets Installed

The marketplace files point to product-specific adapters:

```text
plugins/codex/moos-ivp-skills/
plugins/claude/moos-ivp-skills/
```

Those adapters contain the plugin manifests and copied `skills/` folders.
Root-level docs and scripts stay in the repository for maintainers.

## MOOS-IvP Path

Some skills need a local MOOS-IvP checkout for headers, libraries, examples, and
generators. Prefer setting:

```bash
export MOOS_IVP_ROOT=/path/to/moos-ivp
```

You can also give the path directly in the prompt. Without either, the skills
look in the workspace, nearby folders, and common locations such as
`~/moos-ivp`.

## Maintainers

Edit canonical skills under `skills/`, then refresh and check the plugin copies:

```bash
./scripts/sync_codex_plugin.sh
./scripts/sync_claude_plugin.sh
./scripts/check_plugin_integrity.sh
```

Before sharing a checkout or release candidate, also validate the plugin
payloads:

```bash
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  plugins/codex/moos-ivp-skills
claude plugin validate . --strict
claude plugin validate plugins/claude/moos-ivp-skills --strict
```
