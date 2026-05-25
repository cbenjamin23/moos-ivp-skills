# Agent Notes

## Core Edits

- Edit canonical skills under `skills/`; plugin adapter copies are generated.
- After skill changes, run:

```bash
./scripts/sync_codex_plugin.sh
./scripts/sync_claude_plugin.sh
./scripts/check_plugin_integrity.sh
```

## Commits

- Use Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/

## Official Versioning

- Do not bump versions for repo-only docs/scripts.
- Bump versions only when publishing installable plugin changes.
- Use `./scripts/bump_plugin_version.sh X.Y.Z`; patch = fixes, minor = new
  capability, major = breaking change.
- For a published version, manifests, marketplace metadata, git tag, and GitHub
  Release should all use `X.Y.Z`.
