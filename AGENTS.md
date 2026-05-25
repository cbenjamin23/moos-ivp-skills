# Agent Notes

This repo contains portable MOOS-IvP skills plus product-specific plugin
adapters for Codex and Claude Code.

## Source of Truth

- Edit canonical skills under `skills/`.
- Refresh distributable plugin copies after skill changes:

```bash
./scripts/sync_codex_plugin.sh
./scripts/sync_claude_plugin.sh
./scripts/check_plugin_integrity.sh
```

- Do not hand-edit copied skills under `plugins/codex/.../skills/` or
  `plugins/claude/.../skills/` unless the change is intentionally
  adapter-specific.

## Release Versioning

Use lightweight release discipline.

- Do not bump plugin versions for root docs, maintainer scripts, comments, or
  other changes that do not affect installed plugin behavior.
- Bump patch versions for skill bug fixes or small behavior corrections.
- Bump minor versions for new skills or meaningful new capabilities.
- Bump major versions for breaking changes such as renamed skills, removed
  capabilities, or changed install shape.

Only create a new git tag and GitHub Release when intentionally publishing a new
plugin version. The current `v1.0.0` tag marks the first distributable plugin
payload, not every later repository commit.

## Commit Style

Use Conventional Commits:

https://www.conventionalcommits.org/en/v1.0.0/

Examples:

- `docs: clarify public install commands`
- `fix: correct MOOS-IvP checkout fallback`
- `feat: add alog triage reference workflow`
- `chore(release): bump plugin version to 1.0.1`

## Public Distribution Checks

Before publishing a new plugin version, validate both adapters:

```bash
python3 ~/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py \
  plugins/codex/moos-ivp-skills
claude plugin validate . --strict
claude plugin validate plugins/claude/moos-ivp-skills --strict
./scripts/check_plugin_integrity.sh
```
