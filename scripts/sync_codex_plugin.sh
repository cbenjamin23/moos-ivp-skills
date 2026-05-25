#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_skills="$repo_root/skills"
plugin_root="$repo_root/plugins/codex/moos-ivp-skills"
target_skills="$plugin_root/skills"
validator="$HOME/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py"

if [ ! -d "$source_skills" ]; then
  echo "FAIL missing canonical skills directory: $source_skills" >&2
  exit 1
fi

if [ ! -f "$plugin_root/.codex-plugin/plugin.json" ]; then
  echo "FAIL missing Codex plugin manifest: $plugin_root/.codex-plugin/plugin.json" >&2
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

echo "Synced canonical skills into plugins/codex/moos-ivp-skills/skills"

if [ -f "$validator" ]; then
  python3 "$validator" "$plugin_root"
else
  echo "WARN plugin validator not found at $validator; skipping manifest validation"
fi

"$repo_root/scripts/check_plugin_integrity.sh"
