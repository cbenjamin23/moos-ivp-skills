# Distribution Adapters

The canonical source for this repository is `skills/`. Product-specific plugin
adapters should copy or wrap that source without becoming the only editable
copy.

## Codex

Current adapter:

```text
plugins/codex/moos-ivp-skills/
  .codex-plugin/plugin.json
  skills/
```

Codex discovers this adapter through `.agents/plugins/marketplace.json`.

After editing canonical skills, run:

```bash
./scripts/sync_codex_plugin.sh
```

This refreshes the self-contained Codex skill copy and runs validation.

## Claude Code

Claude Code has a similar plugin marketplace system. Its docs describe:

- marketplace files under `.claude-plugin/marketplace.json`
- plugin manifests under `.claude-plugin/plugin.json`
- plugin directories with components such as `skills/`, `commands/`, `agents/`,
  `hooks/`, MCP servers, and LSP servers
- marketplace install via `/plugin marketplace add ...`
- plugin install via `/plugin install plugin-name@marketplace-name`
- plugin cache installs under `~/.claude/plugins/cache`

Useful references:

- https://code.claude.com/docs/en/plugin-marketplaces
- https://code.claude.com/docs/en/plugins-reference
- https://code.claude.com/docs/en/discover-plugins

Current adapter:

```text
plugins/claude/moos-ivp-skills/
  .claude-plugin/plugin.json
  skills/
```

Claude Code discovers this adapter through `.claude-plugin/marketplace.json`.

After editing canonical skills, run:

```bash
./scripts/sync_claude_plugin.sh
```
