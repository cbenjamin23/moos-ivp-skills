# Scripts

Repository-level helper scripts live here.

- `check_plugin_integrity.sh` validates marketplace/plugin JSON, self-contained
  plugin skill copies, canonical skill parity, skill frontmatter, and stale
  private names/paths.
- `sync_codex_plugin.sh` copies canonical `skills/` into the Codex plugin
  adapter and runs validation. Run it after editing canonical skills and before
  sharing a Codex-distributable checkpoint.
- `sync_claude_plugin.sh` copies canonical `skills/` into the Claude Code
  plugin adapter and runs Claude's strict plugin validators when `claude` is
  available.

These scripts support setup and packaging. They should not be required for an
agent to understand the skills, and the marketplace entries do not install this
directory as part of the plugin payload.

Skill-local scripts are different: scripts under `skills/<skill>/scripts/` are
part of the skill itself and are copied into each shipped plugin adapter.
