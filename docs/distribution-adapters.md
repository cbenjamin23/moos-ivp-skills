# Distribution Adapters

The canonical source for this repository is `skills/`. Product-specific plugin
adapters carry generated copies so installed plugins are self-contained.

The GitHub repository can include maintainer-only files beside the shipped
plugins. Installers read the marketplace file first, then install the adapter
path named by that marketplace entry. In this repo that means `scripts/`,
`docs/`, and root docs are available to maintainers but are not plugin runtime
dependencies.

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

Tested install shape:

```bash
codex plugin marketplace add https://github.com/cbenjamin23/moos-ivp-skills
codex plugin add moos-ivp-skills@moos-ivp-skills
```

## Claude Code

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

Tested install shape:

```bash
claude plugin marketplace add https://github.com/cbenjamin23/moos-ivp-skills
claude plugin install moos-ivp-skills@moos-ivp-skills
```

Local-path installs use the same commands with `/path/to/moos-ivp-skills`
instead of the GitHub URL.

References:

- https://developers.openai.com/codex/plugins/build
- https://code.claude.com/docs/en/plugin-marketplaces
- https://code.claude.com/docs/en/plugins-reference
