# Install

This repository exposes a Codex plugin named `moos-ivp-skills` through the repo
marketplace at `.agents/plugins/marketplace.json`.

## Local Development Install

From any checkout of this repository:

```bash
codex plugin marketplace add /absolute/path/to/moos-ivp-skills
```

Then restart Codex and enable the `MOOS-IvP Skills` plugin if it is not already
enabled.

When changing skills during local development, the Codex adapter currently uses
a symlink from `plugins/codex/moos-ivp-skills/skills` to the canonical `skills/`
directory, so local edits remain visible through the plugin package.

## Git Marketplace Install

Once this repository is published and the branch is ready for other users:

```bash
codex plugin marketplace add charlesbenjamin/moos-ivp-skills --ref main
```

If the marketplace was already added, update it with:

```bash
codex plugin marketplace upgrade
```

Codex installs plugins into its plugin cache and loads the installed copy. For a
release intended for other users, make sure the plugin package is self-contained
and does not depend on local-only symlinks.

## Validate

Before sharing a checkout or release candidate:

```bash
./scripts/check_plugin_integrity.sh
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  plugins/codex/moos-ivp-skills
```
