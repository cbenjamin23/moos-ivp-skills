#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
tmp_files=()
trap 'if [ "${#tmp_files[@]}" -gt 0 ]; then rm -f "${tmp_files[@]}"; fi' EXIT

make_tmp() {
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/moos_ivp_integrity.XXXXXX")"
  tmp_files+=("$tmp")
  printf '%s\n' "$tmp"
}

note() {
  printf '%s\n' "$*"
}

fail_msg() {
  printf 'FAIL %s\n' "$*" >&2
  fail=1
}

check_json() {
  local rel="$1"
  if [ ! -f "$repo_root/$rel" ]; then
    fail_msg "missing $rel"
    return
  fi
  if python3 -m json.tool "$repo_root/$rel" >/dev/null; then
    note "PASS json $rel"
  else
    fail_msg "invalid json $rel"
  fi
}

check_json ".agents/plugins/marketplace.json"
check_json "plugins/codex/moos-ivp-skills/.codex-plugin/plugin.json"
check_json ".claude-plugin/marketplace.json"
check_json "plugins/claude/moos-ivp-skills/.claude-plugin/plugin.json"

if python3 - "$repo_root" <<'PY'
import json
import re
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
version_re = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")

def load_json(rel):
    path = repo_root / rel
    with path.open() as handle:
        return json.load(handle)

try:
    codex = load_json("plugins/codex/moos-ivp-skills/.codex-plugin/plugin.json").get("version")
    claude = load_json("plugins/claude/moos-ivp-skills/.claude-plugin/plugin.json").get("version")
    marketplace = load_json(".claude-plugin/marketplace.json")
    claude_marketplace = None
    for plugin in marketplace.get("plugins", []):
        if plugin.get("name") == "moos-ivp-skills":
            claude_marketplace = plugin.get("version")
            break

    versions = {
        "Codex manifest": codex,
        "Claude manifest": claude,
        "Claude marketplace": claude_marketplace,
    }

    errors = []
    for label, version in versions.items():
        if not isinstance(version, str) or not version_re.fullmatch(version):
            errors.append(f"{label} version is not X.Y.Z: {version!r}")

    if len(set(versions.values())) != 1:
        errors.append(
            "plugin versions differ: "
            + ", ".join(f"{label}={version!r}" for label, version in versions.items())
        )
except Exception as exc:
    errors = [f"unable to read plugin versions: {exc}"]

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    raise SystemExit(1)
PY
then
  note "PASS plugin versions are synchronized"
else
  fail_msg "plugin versions must match across manifests and marketplace metadata"
fi

plugin_skills="$repo_root/plugins/codex/moos-ivp-skills/skills"
if [ -d "$plugin_skills" ] && [ ! -L "$plugin_skills" ]; then
  note "PASS plugin skills directory is self-contained"
else
  fail_msg "plugin skills directory must be a real self-contained directory: plugins/codex/moos-ivp-skills/skills"
fi

if [ -d "$plugin_skills" ] && [ ! -L "$plugin_skills" ]; then
  skill_diff_tmp="$(make_tmp)"
  if diff -qr "$repo_root/skills" "$plugin_skills" >"$skill_diff_tmp" 2>/dev/null; then
    note "PASS plugin skills match canonical skills"
  else
    cat "$skill_diff_tmp" >&2
    fail_msg "Codex plugin skills differ from canonical skills; run scripts/sync_codex_plugin.sh"
  fi
fi

claude_plugin_skills="$repo_root/plugins/claude/moos-ivp-skills/skills"
if [ -d "$claude_plugin_skills" ] && [ ! -L "$claude_plugin_skills" ]; then
  note "PASS Claude plugin skills directory is self-contained"
else
  fail_msg "Claude plugin skills directory must be a real self-contained directory: plugins/claude/moos-ivp-skills/skills"
fi

if [ -d "$claude_plugin_skills" ] && [ ! -L "$claude_plugin_skills" ]; then
  claude_skill_diff_tmp="$(make_tmp)"
  if diff -qr "$repo_root/skills" "$claude_plugin_skills" >"$claude_skill_diff_tmp" 2>/dev/null; then
    note "PASS Claude plugin skills match canonical skills"
  else
    cat "$claude_skill_diff_tmp" >&2
    fail_msg "Claude plugin skills differ from canonical skills; run scripts/sync_claude_plugin.sh"
  fi
fi

skill_count=0
for skill_md in "$repo_root"/skills/*/SKILL.md; do
  [ -f "$skill_md" ] || continue
  skill_count=$((skill_count + 1))
  skill_dir="$(basename "$(dirname "$skill_md")")"
  name_line="$(awk '
    /^---$/ { fence++; next }
    fence == 1 && /^name:[[:space:]]*/ {
      sub(/^name:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$skill_md")"
  desc_line="$(awk '
    /^---$/ { fence++; next }
    fence == 1 && /^description:[[:space:]]*/ {
      print
      exit
    }
  ' "$skill_md")"
  if [ "$name_line" != "$skill_dir" ]; then
    fail_msg "$skill_dir SKILL.md name mismatch: ${name_line:-missing}"
  else
    note "PASS skill name $skill_dir"
  fi
  if [ -z "$desc_line" ]; then
    fail_msg "$skill_dir missing description"
  fi
  if [ ! -f "$repo_root/skills/$skill_dir/agents/openai.yaml" ]; then
    fail_msg "$skill_dir missing agents/openai.yaml"
  else
    openai_yaml="$repo_root/skills/$skill_dir/agents/openai.yaml"
    if ! grep -Eq '^[[:space:]]+icon_small:[[:space:]]+"?\.\/assets\/moos-ivp-logo\.png"?[[:space:]]*$' "$openai_yaml"; then
      fail_msg "$skill_dir agents/openai.yaml missing icon_small ./assets/moos-ivp-logo.png"
    fi
    if ! grep -Eq '^[[:space:]]+icon_large:[[:space:]]+"?\.\/assets\/moos-ivp-logo\.png"?[[:space:]]*$' "$openai_yaml"; then
      fail_msg "$skill_dir agents/openai.yaml missing icon_large ./assets/moos-ivp-logo.png"
    fi
    if [ ! -f "$repo_root/skills/$skill_dir/assets/moos-ivp-logo.png" ]; then
      fail_msg "$skill_dir missing assets/moos-ivp-logo.png"
    fi
  fi
done

if [ "$skill_count" -eq 0 ]; then
  fail_msg "no skills found under skills/*/SKILL.md"
fi

private_path_tmp="$(make_tmp)"
if grep -R -n --exclude-dir=.git \
  --exclude=bump_plugin_version.sh \
  --exclude=check_plugin_integrity.sh \
  --exclude=sync_codex_plugin.sh \
  --exclude=sync_claude_plugin.sh \
  '/Documents/Codex/' "$repo_root" >"$private_path_tmp" 2>/dev/null; then
  cat "$private_path_tmp" >&2
  fail_msg "private Codex workspace path found"
fi

legacy_alog_skill='moos-alog''-cli-tools'
legacy_mission_cycle='moos-ivp''-mission-cycle'
legacy_cicd_repo='moos-ivp''-cicd'
legacy_missions_auto='missions''-auto'
legacy_missions_auto_key='missions''_auto'
legacy_cicd_key='moos_ivp''_cicd'
stale_name_tmp="$(make_tmp)"
if grep -R -n --exclude-dir=.git \
  --exclude=bump_plugin_version.sh \
  --exclude=check_plugin_integrity.sh \
  --exclude=sync_codex_plugin.sh \
  --exclude=sync_claude_plugin.sh \
  -e "$legacy_alog_skill" \
  -e "$legacy_mission_cycle" \
  -e "$legacy_cicd_repo" \
  -e "$legacy_missions_auto" \
  -e "$legacy_missions_auto_key" \
  -e "$legacy_cicd_key" \
  "$repo_root/skills" "$repo_root/README.md" "$repo_root/.agents" "$repo_root/.claude-plugin" "$repo_root/plugins" "$repo_root/scripts" \
  >"$stale_name_tmp" 2>/dev/null; then
  cat "$stale_name_tmp" >&2
  fail_msg "stale skill name found in active distribution surface"
fi

legacy_teardown='harness''_teardown'
teardown_stale_tmp="$(make_tmp)"
if grep -R -n --exclude-dir=.git \
  --exclude=bump_plugin_version.sh \
  --exclude=check_plugin_integrity.sh \
  --exclude=sync_codex_plugin.sh \
  --exclude=sync_claude_plugin.sh \
  "$legacy_teardown" \
  "$repo_root/skills/moos-ivp-harness-builder" \
  "$repo_root/skills/moos-ivp-eval-mission-builder" \
  >"$teardown_stale_tmp" 2>/dev/null; then
  cat "$teardown_stale_tmp" >&2
  fail_msg "legacy teardown helper name found in eval/harness skills"
fi

eval_teardown="$repo_root/skills/moos-ivp-eval-mission-builder/assets/moos_scoped_teardown.sh"
harness_asset="$repo_root/skills/moos-ivp-harness-builder/assets/moos_scoped_teardown.sh"
if [ ! -f "$eval_teardown" ]; then
  fail_msg "missing eval skill moos_scoped_teardown.sh asset"
elif [ ! -x "$eval_teardown" ]; then
  fail_msg "eval skill moos_scoped_teardown.sh is not executable"
fi
if [ ! -f "$harness_asset" ]; then
  fail_msg "missing harness skill moos_scoped_teardown.sh asset"
elif [ ! -x "$harness_asset" ]; then
  fail_msg "harness skill moos_scoped_teardown.sh is not executable"
fi
if [ -f "$eval_teardown" ] && [ -f "$harness_asset" ]; then
  if cmp -s "$eval_teardown" "$harness_asset"; then
    note "PASS duplicated moos_scoped_teardown.sh assets match"
  else
    fail_msg "eval and harness moos_scoped_teardown.sh assets differ"
  fi
fi

teardown_test="$repo_root/scripts/test_moos_scoped_teardown.sh"
if [ ! -f "$teardown_test" ]; then
  fail_msg "missing teardown helper behavioral test"
elif bash "$teardown_test"; then
  note "PASS teardown helper behavioral tests"
else
  fail_msg "teardown helper behavioral tests failed"
fi

if [ "$fail" -eq 0 ]; then
  note "PASS plugin integrity checks ($skill_count skills)"
fi

exit "$fail"
