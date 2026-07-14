#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2329
# Test functions are invoked by name through run_test.
set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
helper="$repo_root/skills/moos-ivp-harness-builder/assets/moos_scoped_teardown.sh"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/moos_scoped_teardown_test.XXXXXX")"
fail=0

trap 'rm -rf "$tmp_root"' EXIT

pass() {
  printf 'PASS %s\n' "$1"
}

fail_test() {
  printf 'FAIL %s\n' "$1" >&2
  fail=1
}

run_test() {
  local name="$1"
  local function_name="$2"

  if "$function_name"; then
    pass "$name"
  else
    fail_test "$name"
  fi
}

test_nounset_without_extra_apps() (
  local apps
  local err_file="$tmp_root/nounset.err"

  unset MOOS_SCOPED_TEARDOWN_EXTRA_APPS
  set -u
  # shellcheck source=/dev/null
  . "$helper"

  apps=$(moos_scoped_teardown_apps_for_root "$tmp_root" 2>"$err_file") || return 1
  [ ! -s "$err_file" ] || return 1
  printf '%s\n' "$apps" | grep -qx 'MOOSDB' || return 1
  [ "$MOOS_SCOPED_TEARDOWN_EXTRA_APPS" = "" ]
)

test_extra_apps_preserved() (
  local apps

  MOOS_SCOPED_TEARDOWN_EXTRA_APPS="pCustomOne pCustomTwo"
  # shellcheck source=/dev/null
  . "$helper"

  apps=$(moos_scoped_teardown_apps_for_root "$tmp_root") || return 1
  printf '%s\n' "$apps" | grep -qx 'pCustomOne' || return 1
  printf '%s\n' "$apps" | grep -qx 'pCustomTwo'
)

test_default_grace_periods() (
  # shellcheck source=/dev/null
  . "$helper"

  [ "$MOOS_SCOPED_TEARDOWN_GRACE_INT_SECONDS" = "3" ] || return 1
  [ "$MOOS_SCOPED_TEARDOWN_GRACE_TERM_SECONDS" = "3" ] || return 1
  [ "$MOOS_SCOPED_TEARDOWN_GRACE_KILL_SECONDS" = "1" ]
)

test_all_discovery_backends_fail() (
  local pids

  # shellcheck source=/dev/null
  . "$helper"
  moos_scoped_teardown_pids_for_root_procfs() { return 1; }
  moos_scoped_teardown_pids_for_root_lsof() { return 1; }

  if pids=$(moos_scoped_teardown_pids_for_root "$tmp_root"); then
    return 1
  fi
  [ "$pids" = "" ]
)

test_lsof_fallback_is_used() (
  local pids

  # shellcheck source=/dev/null
  . "$helper"
  moos_scoped_teardown_pids_for_root_procfs() { return 1; }
  moos_scoped_teardown_pids_for_root_lsof() { printf '4321\n'; }

  pids=$(moos_scoped_teardown_pids_for_root "$tmp_root") || return 1
  [ "$pids" = "4321" ]
)

test_successful_empty_discovery() (
  local pids

  # shellcheck source=/dev/null
  . "$helper"
  moos_scoped_teardown_pids_for_root_procfs() { return 0; }
  moos_scoped_teardown_pids_for_root_lsof() { return 1; }

  pids=$(moos_scoped_teardown_pids_for_root "$tmp_root") || return 1
  [ "$pids" = "" ]
)

test_stop_root_reports_discovery_failure() (
  local err_file="$tmp_root/stop_root.err"

  # shellcheck source=/dev/null
  . "$helper"
  moos_scoped_teardown_pids_for_root() { return 1; }

  if moos_scoped_teardown_stop_root "$tmp_root" 2>"$err_file"; then
    return 1
  fi
  grep -q 'unable to inspect scoped processes' "$err_file"
)

test_wait_clear_distinguishes_discovery_failure() (
  local err_file="$tmp_root/wait_clear.err"
  local status

  # shellcheck source=/dev/null
  . "$helper"
  moos_scoped_teardown_pids_for_root() { return 1; }

  moos_scoped_teardown_wait_clear "$tmp_root" 1 2>"$err_file"
  status=$?
  [ "$status" -eq 2 ] || return 1
  grep -q 'unable to inspect scoped processes' "$err_file"
)

test_wait_clear_uses_elapsed_seconds() (
  local call_file="$tmp_root/wait_elapsed.calls"
  local calls
  local status

  # shellcheck source=/dev/null
  . "$helper"
  : > "$call_file"
  moos_scoped_teardown_pids_for_root_checked() {
    printf 'call\n' >> "$call_file"
    printf '7654\n'
  }
  sleep() { SECONDS=$((SECONDS + 1)); }

  SECONDS=0
  moos_scoped_teardown_wait_clear "$tmp_root" 3
  status=$?
  calls=$(wc -l < "$call_file" | tr -d ' ')
  [ "$status" -eq 1 ] || return 1
  [ "$SECONDS" -eq 3 ] || return 1
  [ "$calls" -eq 4 ]
)

test_stop_root_does_not_escalate_during_grace() (
  local call_file="$tmp_root/stop_grace.calls"
  local count
  local signal_file="$tmp_root/stop_grace.signals"

  # shellcheck source=/dev/null
  . "$helper"
  printf '0\n' > "$call_file"
  : > "$signal_file"
  moos_scoped_teardown_pids_for_root_checked() {
    count=$(cat "$call_file")
    count=$((count + 1))
    printf '%s\n' "$count" > "$call_file"
    if [ "$count" -lt 3 ]; then
      printf '7654\n'
    fi
  }
  moos_scoped_teardown_signal_pids() { printf '%s\n' "$1" >> "$signal_file"; }
  sleep() { SECONDS=$((SECONDS + 1)); }

  SECONDS=0
  moos_scoped_teardown_stop_root "$tmp_root" || return 1
  [ "$(tr '\n' ' ' < "$signal_file")" = "INT " ]
)

test_invalid_grace_period_is_an_error() (
  local err_file="$tmp_root/invalid_grace.err"
  local status

  # shellcheck source=/dev/null
  . "$helper"
  moos_scoped_teardown_wait_clear "$tmp_root" invalid 2>"$err_file"
  status=$?
  [ "$status" -eq 2 ] || return 1
  grep -q 'invalid grace period' "$err_file"
)

test_lsof_backend_matches_scoped_cwd() (
  local pids
  local canonical_root

  # shellcheck source=/dev/null
  . "$helper"
  canonical_root=$(cd "$tmp_root" && pwd -P)
  lsof() {
    printf 'p7654\ncpMissionEval\nfcwd\nn%s\n' "$canonical_root"
  }

  pids=$(moos_scoped_teardown_pids_for_root_lsof "$tmp_root") || return 1
  [ "$pids" = "7654" ]
)

test_lsof_backend_accepts_no_scoped_match() (
  local pids

  # shellcheck source=/dev/null
  . "$helper"
  lsof() {
    printf 'p7654\ncpMissionEval\nfcwd\nn/somewhere/else\n'
  }

  pids=$(moos_scoped_teardown_pids_for_root_lsof "$tmp_root") || return 1
  [ "$pids" = "" ]
)

test_lsof_backend_propagates_failure() (
  # shellcheck source=/dev/null
  . "$helper"
  lsof() { return 1; }

  ! moos_scoped_teardown_pids_for_root_lsof "$tmp_root" >/dev/null
)

test_callers_propagate_teardown_failure() (
  local example="$repo_root/skills/moos-ivp-harness-builder/references/example-harness-zlaunch.md"
  local guidance="$repo_root/skills/moos-ivp-harness-builder/references/scoped-teardown.md"
  local live_check="$repo_root/skills/moos-ivp-eval-mission-builder/scripts/live_check_eval_mission.sh"

  if grep -F 'moos_scoped_teardown_stop_root "$mission_root" >/dev/null 2>&1 || true' "$guidance" >/dev/null; then
    return 1
  fi
  if grep -F 'moos_scoped_teardown_stop_root "$1" >/dev/null 2>&1 || true' "$example" >/dev/null; then
    return 1
  fi
  if grep -F 'moos_scoped_teardown_stop_root "$WORKDIR" >/dev/null 2>&1 || true' "$live_check" >/dev/null; then
    return 1
  fi
  grep -q 'reason=teardown_error' "$example" || return 1
  grep -q 'preserving workdir' "$live_check"
)

run_test "nounset mode without extra apps" test_nounset_without_extra_apps
run_test "configured extra apps are preserved" test_extra_apps_preserved
run_test "default grace periods use seconds" test_default_grace_periods
run_test "all discovery backends failing returns failure" test_all_discovery_backends_fail
run_test "lsof fallback is used" test_lsof_fallback_is_used
run_test "successful empty discovery remains success" test_successful_empty_discovery
run_test "stop_root reports discovery failure" test_stop_root_reports_discovery_failure
run_test "wait_clear distinguishes discovery failure" test_wait_clear_distinguishes_discovery_failure
run_test "wait_clear uses elapsed seconds" test_wait_clear_uses_elapsed_seconds
run_test "stop_root avoids escalation during grace" test_stop_root_does_not_escalate_during_grace
run_test "invalid grace periods return an error" test_invalid_grace_period_is_an_error
run_test "lsof backend matches a scoped cwd" test_lsof_backend_matches_scoped_cwd
run_test "lsof backend accepts no scoped match" test_lsof_backend_accepts_no_scoped_match
run_test "lsof backend propagates failure" test_lsof_backend_propagates_failure
run_test "callers propagate teardown failure" test_callers_propagate_teardown_failure

exit "$fail"
