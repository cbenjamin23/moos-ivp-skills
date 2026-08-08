#!/usr/bin/env bash
set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
checker="$repo_root/skills/moos-ivp-harness-builder/scripts/static_check_harness.sh"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/static_check_harness_test.XXXXXX")"
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
  local harness_dir="$tmp_root/$name"

  mkdir -p "$harness_dir"
  printf '# Cases\n\n- baseline\n- alternate\n' > "$harness_dir/README.md"
  cat > "$harness_dir/zlaunch.sh" <<'EOF'
#!/usr/bin/env bash
if [ "${BASH_VERSINFO[0]}" -lt 5 ]; then
  echo "Bash >= 5.1 is required" >&2
  exit 2
fi
PORT_BASE=9000
PORT_STRIDE=30
PSHARE_OFFSET=$((PORT_STRIDE / 2))
JOBS=1
KEEP_WORKDIRS=no
for arg in "$@"; do
  case "$arg" in
    --case=*) SELECTED_CASE="${arg#--case=}" ;;
    --jobs=*) JOBS="${arg#--jobs=}" ;;
    --port_base=*) PORT_BASE="${arg#--port_base=}" ;;
    --max_time=*) MAX_TIME="${arg#--max_time=}" ;;
    --keep_workdirs) KEEP_WORKDIRS=yes ;;
  esac
done
get_case_config() {
  case "$1" in
    baseline|alternate) return 0 ;;
    *) return 1 ;;
  esac
}
run_case() {
  local case_name="$1"
  local workdir
  workdir="$(mktemp -d)"
  cp -R mission/. "$workdir/"
  shore_mport=$PORT_BASE
  veh_mport=$((PORT_BASE + 1))
  shore_pshare=$((PORT_BASE + PSHARE_OFFSET))
  veh_pshare=$((PORT_BASE + PSHARE_OFFSET + 1))
  TEARDOWN_HELPER=scripts/moos_scoped_teardown.sh
  moos_scoped_teardown_stop_root "$workdir"
  printf 'case=%s grade=fail reason=missing_result\n' "$case_name"
}
run_case baseline &
wait -p DONE_PID -n
result_rows=1; if [ "$result_rows" -eq 0 ]; then echo "no cases selected or no case result rows" >&2; exit 1; fi
EOF
  chmod +x "$harness_dir/zlaunch.sh"
  printf '%s\n' "$harness_dir"
}

expect_pass() {
  local harness_dir="$1"
  "$checker" "$harness_dir" >/dev/null 2>&1
}

expect_fail_with() {
  local harness_dir="$1"
  local pattern="$2"
  local output

  if output="$($checker "$harness_dir" 2>&1)"; then
    printf '%s\n' "$output" >&2
    return 1
  fi
  printf '%s\n' "$output" | grep -Fq "$pattern"
}

test_valid_rolling_harness() {
  local harness_dir
  harness_dir="$(make_fixture valid)"
  expect_pass "$harness_dir"
}

test_missing_jobs_fails() {
  local harness_dir
  harness_dir="$(make_fixture missing_jobs)"
  sed -i.bak '/--jobs=/d' "$harness_dir/zlaunch.sh"
  expect_fail_with "$harness_dir" 'FAIL zlaunch.sh omits required --jobs'
}

test_batch_barrier_fails() {
  local harness_dir
  harness_dir="$(make_fixture batch_barrier)"
  sed -i.bak 's/wait -p DONE_PID -n/wait "$case_pid"/' "$harness_dir/zlaunch.sh"
  expect_fail_with "$harness_dir" 'FAIL zlaunch.sh appears to use legacy batch-barrier waits'
}

test_missing_result_guard_fails() {
  local harness_dir
  harness_dir="$(make_fixture missing_result_guard)"
  sed -i.bak '/result_rows/d' "$harness_dir/zlaunch.sh"
  expect_fail_with "$harness_dir" 'FAIL zlaunch.sh does not show an obvious zero-selected/zero-result guard'
}

test_high_default_port_warns_only() {
  local harness_dir
  local output
  harness_dir="$(make_fixture high_port)"
  sed -i.bak 's/^PORT_BASE=9000$/PORT_BASE=30000/' "$harness_dir/zlaunch.sh"
  output="$($checker "$harness_dir" 2>&1)" || {
    printf '%s\n' "$output" >&2
    return 1
  }
  printf '%s\n' "$output" | grep -Fq 'WARN zlaunch.sh defaults to a high PORT_BASE'
}

test_custom_pshare_layout_warns_only() {
  local harness_dir
  local output
  harness_dir="$(make_fixture custom_pshare)"
  sed -i.bak 's/^PSHARE_OFFSET=.*/PSHARE_LAYOUT_OFFSET=10/' "$harness_dir/zlaunch.sh"
  sed -i.bak 's/PSHARE_OFFSET/PSHARE_LAYOUT_OFFSET/g' "$harness_dir/zlaunch.sh"
  output="$($checker "$harness_dir" 2>&1)" || {
    printf '%s\n' "$output" >&2
    return 1
  }
  printf '%s\n' "$output" | grep -Fq 'WARN zlaunch.sh does not show the midpoint pShare offset pattern'
}

if test_valid_rolling_harness; then
  pass "valid rolling harness passes"
else
  fail_test "valid rolling harness passes"
fi
if test_missing_jobs_fails; then
  pass "missing --jobs fails"
else
  fail_test "missing --jobs fails"
fi
if test_batch_barrier_fails; then
  pass "batch-barrier scheduling fails"
else
  fail_test "batch-barrier scheduling fails"
fi
if test_missing_result_guard_fails; then
  pass "missing result guard fails"
else
  fail_test "missing result guard fails"
fi
if test_high_default_port_warns_only; then
  pass "high default port remains advisory"
else
  fail_test "high default port remains advisory"
fi
if test_custom_pshare_layout_warns_only; then
  pass "custom pShare layout remains advisory"
else
  fail_test "custom pShare layout remains advisory"
fi

exit "$fail"
