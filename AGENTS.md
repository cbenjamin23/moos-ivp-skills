# Agent Notes

- Edit canonical skills under `skills/`.
- After skill changes, run the sync scripts and integrity check:

```bash
./scripts/sync_codex_plugin.sh
./scripts/sync_claude_plugin.sh
./scripts/check_plugin_integrity.sh
```

- Use Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
- Version only installable plugin changes, not repo-only docs/scripts.
- Keep published versions synchronized across plugin manifests, marketplace
  metadata, git tag, and GitHub Release.
- Semver: patch = fixes, minor = new capability, major = breaking change.
