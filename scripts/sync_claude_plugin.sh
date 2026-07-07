#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_skills="$repo_root/skills"
plugin_root="$repo_root/plugins/claude/moos-ivp-skills"
target_skills="$plugin_root/skills"
claude_bin="${CLAUDE_BIN:-$HOME/.local/bin/claude}"

if [ ! -x "$claude_bin" ] && command -v claude >/dev/null 2>&1; then
  claude_bin="$(command -v claude)"
fi

if [ ! -d "$source_skills" ]; then
  echo "FAIL missing canonical skills directory: $source_skills" >&2
  exit 1
fi

if [ ! -f "$plugin_root/.claude-plugin/plugin.json" ]; then
  echo "FAIL missing Claude plugin manifest: $plugin_root/.claude-plugin/plugin.json" >&2
  exit 1
fi

rm -rf "$target_skills"
mkdir -p "$target_skills"

(
  cd "$source_skills"
  tar -cf - .
) | (
  cd "$target_skills"
  tar -xpf -
)

echo "Synced canonical skills into plugins/claude/moos-ivp-skills/skills"

if [ -x "$claude_bin" ]; then
  "$claude_bin" plugin validate "$repo_root" --strict
  "$claude_bin" plugin validate "$plugin_root" --strict
else
  echo "WARN claude executable not found; skipping Claude plugin validation"
fi
