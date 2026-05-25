#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  printf 'usage: %s X.Y.Z\n' "$(basename "$0")" >&2
  exit 2
fi

version="$1"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'version must use strict semver: X.Y.Z\n' >&2
  exit 2
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$repo_root" "$version" <<'PY'
import json
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
version = sys.argv[2]

paths = [
    repo_root / "plugins/codex/moos-ivp-skills/.codex-plugin/plugin.json",
    repo_root / "plugins/claude/moos-ivp-skills/.claude-plugin/plugin.json",
]

for path in paths:
    data = json.loads(path.read_text())
    data["version"] = version
    path.write_text(json.dumps(data, indent=2) + "\n")

marketplace_path = repo_root / ".claude-plugin/marketplace.json"
marketplace = json.loads(marketplace_path.read_text())
for plugin in marketplace.get("plugins", []):
    if plugin.get("name") == "moos-ivp-skills":
        plugin["version"] = version
        break
else:
    raise SystemExit("missing moos-ivp-skills entry in .claude-plugin/marketplace.json")

marketplace_path.write_text(json.dumps(marketplace, indent=2) + "\n")

for path in [*paths, marketplace_path]:
    print(f"updated {path.relative_to(repo_root)}")
PY
