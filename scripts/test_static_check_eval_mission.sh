#!/usr/bin/env bash
set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
checker="$repo_root/skills/moos-ivp-eval-mission-builder/scripts/static_check_eval_mission.sh"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/static_check_eval_mission_test.XXXXXX")"
fail=0

trap 'rm -rf "$tmp_root"' EXIT

pass() {
  printf 'PASS %s\n' "$1"
}

fail_test() {
  printf 'FAIL %s\n' "$1" >&2
  fail=1
}

make_fixture() {
  local name="$1"
  local lead="$2"
  local mission_dir="$tmp_root/$name"

  mkdir -p "$mission_dir"
  printf '# Eval checker fixture\n' > "$mission_dir/README.md"
  printf '#!/usr/bin/env bash\n' > "$mission_dir/launch.sh"
  cat > "$mission_dir/zlaunch.sh" <<'EOF'
#!/usr/bin/env bash
: > results.txt
xlaunch.sh --max_time=10
grep -q 'grade=' results.txt
TEARDOWN_HELPER=scripts/moos_scoped_teardown.sh
EOF
  cat > "$mission_dir/meta_shoreside.moos" <<EOF
ProcessConfig = pAutoPoke
{
  flag = EVENT_A=false
  flag = EVENT_B=false
}

ProcessConfig = pMissionEval
{
  lead_condition = $lead
  pass_condition = RESULT_OK = true
  result_flag = MISSION_EVALUATED = true
  report_file = results.txt
  report_column = grade=\$[GRADE]
}
EOF

  chmod +x "$mission_dir/launch.sh" "$mission_dir/zlaunch.sh"
  printf '%s\n' "$mission_dir"
}

test_textual_or_is_allowed() {
  local mission_dir
  local output

  mission_dir="$(make_fixture textual_or '(EVENT_A = true) or (EVENT_B = true)')"
  output="$($checker "$mission_dir" 2>&1)" || {
    printf '%s\n' "$output" >&2
    return 1
  }
  printf '%s\n' "$output" | grep -q 'PASS eval mission structural checks'
}

test_symbolic_or_is_rejected() {
  local mission_dir
  local output

  mission_dir="$(make_fixture symbolic_or '(EVENT_A = true) || (EVENT_B = true)')"
  if output="$($checker "$mission_dir" 2>&1)"; then
    printf '%s\n' "$output" >&2
    return 1
  fi
  printf '%s\n' "$output" | grep -q 'FAIL unsupported || in lead_condition'
}

if test_textual_or_is_allowed; then
  pass "textual or lead_condition is allowed"
else
  fail_test "textual or lead_condition is allowed"
fi

if test_symbolic_or_is_rejected; then
  pass "symbolic || lead_condition is rejected"
else
  fail_test "symbolic || lead_condition is rejected"
fi

exit "$fail"
