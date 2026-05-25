#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

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

plugin_skills="$repo_root/plugins/codex/moos-ivp-skills/skills"
if [ -d "$plugin_skills" ] && [ ! -L "$plugin_skills" ]; then
  note "PASS plugin skills directory is self-contained"
else
  fail_msg "plugin skills directory must be a real self-contained directory: plugins/codex/moos-ivp-skills/skills"
fi

if [ -d "$plugin_skills" ] && [ ! -L "$plugin_skills" ]; then
  if diff -qr "$repo_root/skills" "$plugin_skills" >/tmp/moos_ivp_skill_diff.$$ 2>/dev/null; then
    note "PASS plugin skills match canonical skills"
  else
    cat /tmp/moos_ivp_skill_diff.$$ >&2
    fail_msg "plugin skills differ from canonical skills; run scripts/sync_codex_plugin.sh"
  fi
  rm -f /tmp/moos_ivp_skill_diff.$$
fi

claude_plugin_skills="$repo_root/plugins/claude/moos-ivp-skills/skills"
if [ -d "$claude_plugin_skills" ] && [ ! -L "$claude_plugin_skills" ]; then
  note "PASS Claude plugin skills directory is self-contained"
else
  fail_msg "Claude plugin skills directory must be a real self-contained directory: plugins/claude/moos-ivp-skills/skills"
fi

if [ -d "$claude_plugin_skills" ] && [ ! -L "$claude_plugin_skills" ]; then
  if diff -qr "$repo_root/skills" "$claude_plugin_skills" >/tmp/moos_ivp_claude_skill_diff.$$ 2>/dev/null; then
    note "PASS Claude plugin skills match canonical skills"
  else
    cat /tmp/moos_ivp_claude_skill_diff.$$ >&2
    fail_msg "Claude plugin skills differ from canonical skills; run scripts/sync_claude_plugin.sh"
  fi
  rm -f /tmp/moos_ivp_claude_skill_diff.$$
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
  fi
done

if [ "$skill_count" -eq 0 ]; then
  fail_msg "no skills found under skills/*/SKILL.md"
fi

if grep -R -n --exclude-dir=.git --exclude=check_plugin_integrity.sh --exclude=sync_codex_plugin.sh --exclude=sync_claude_plugin.sh \
  '/Documents/Codex/' "$repo_root" >/tmp/moos_ivp_skill_paths.$$ 2>/dev/null; then
  cat /tmp/moos_ivp_skill_paths.$$ >&2
  fail_msg "private Codex workspace path found"
fi
rm -f /tmp/moos_ivp_skill_paths.$$

legacy_alog_skill='moos-alog''-cli-tools'
legacy_mission_cycle='moos-ivp''-mission-cycle'
if grep -R -n --exclude-dir=.git \
  --exclude=check_plugin_integrity.sh \
  --exclude=sync_codex_plugin.sh \
  --exclude=sync_claude_plugin.sh \
  -e "$legacy_alog_skill" \
  -e "$legacy_mission_cycle" \
  "$repo_root/skills" "$repo_root/README.md" "$repo_root/.agents" "$repo_root/.claude-plugin" "$repo_root/plugins" "$repo_root/config" "$repo_root/scripts" \
  >/tmp/moos_ivp_skill_stale.$$ 2>/dev/null; then
  cat /tmp/moos_ivp_skill_stale.$$ >&2
  fail_msg "stale skill name found in active distribution surface"
fi
rm -f /tmp/moos_ivp_skill_stale.$$

legacy_teardown='harness''_teardown'
if grep -R -n --exclude-dir=.git --exclude=check_plugin_integrity.sh --exclude=sync_codex_plugin.sh --exclude=sync_claude_plugin.sh \
  "$legacy_teardown" \
  "$repo_root/skills/moos-ivp-harness-builder" \
  "$repo_root/skills/moos-ivp-eval-mission-builder" \
  >/tmp/moos_ivp_teardown_stale.$$ 2>/dev/null; then
  cat /tmp/moos_ivp_teardown_stale.$$ >&2
  fail_msg "legacy teardown helper name found in eval/harness skills"
fi
rm -f /tmp/moos_ivp_teardown_stale.$$

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

if [ "$fail" -eq 0 ]; then
  note "PASS plugin integrity checks ($skill_count skills)"
fi

exit "$fail"
