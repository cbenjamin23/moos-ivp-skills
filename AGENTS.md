# Agent Notes

- Edit canonical skills under `skills/`.
- After skill changes, run the sync scripts and integrity check:

```bash
./scripts/sync_codex_plugin.sh
./scripts/sync_claude_plugin.sh
./scripts/check_plugin_integrity.sh
```

- Use Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
- Use lightweight release discipline: normal commits do not need a version bump.
- Bump plugin versions, tag, and create a GitHub Release only when intentionally
  publishing a new installable plugin version.
- Do not bump versions for root docs or maintainer-only scripts.
