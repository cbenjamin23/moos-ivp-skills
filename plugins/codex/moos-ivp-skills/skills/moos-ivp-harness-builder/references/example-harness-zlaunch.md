# Example Harness `zlaunch.sh` Skeleton

This is a modern generated-harness skeleton for the harness launcher placed at:

```text
repo-root/
  scripts/
    moos_scoped_teardown.sh
  missions/
    <family>_missions/
      <stem_mission>/
        zlaunch.sh
        meta_shoreside.moos
        meta_vehicle.moos
        meta_vehicle.bhv
  harnesses/
    <family>_harnesses/
      HNN-<harness_name>/
        README.md
        zlaunch.sh
        results.txt
        <case-patches>.xmoos
        <case-patches>.xbhv
```

For a shorter `harnesses/<harness_name>/` layout, compute `REPO_DIR` with
`../..` instead of `../../..`. The harness should copy the stem mission into a
per-case workdir before patching or launching it. Do not patch the shared stem
directory when more than one case may be active.

```bash
#!/usr/bin/env bash

need_bash=5.1
if [ -z "${BASH_VERSION:-}" ]; then
  echo "zlaunch.sh: run this harness as ./zlaunch.sh with Bash >= $need_bash." >&2
  exit 2
fi

have_bash51() {
  (( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1) ))
}

if ! have_bash51; then
  if [ "${HARNESS_DISABLE_BASH_REEXEC:-}" != 1 ]; then
    for bash_candidate in "${HARNESS_BASH:-}" /opt/homebrew/bin/bash /usr/local/bin/bash /home/linuxbrew/.linuxbrew/bin/bash; do
      [ -n "$bash_candidate" ] && [ -x "$bash_candidate" ] || continue
      if "$bash_candidate" -c '(( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1) ))' 2>/dev/null; then
        echo "zlaunch.sh: re-running with $bash_candidate for Bash >= $need_bash" >&2
        exec "$bash_candidate" "$0" "$@"
      fi
    done
  fi
  echo "zlaunch.sh: Bash >= $need_bash is required for rolling --jobs scheduling." >&2
  echo "Detected Bash: $BASH_VERSION" >&2
  echo "On macOS, install Homebrew Bash or run: HARNESS_BASH=/opt/homebrew/bin/bash ./zlaunch.sh" >&2
  exit 2
fi

set -u

ME=$(basename "$0")
HARNESS_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "$HARNESS_DIR/../../.." && pwd)
MISSION_DIR="$REPO_DIR/missions/<family>_missions/<stem_mission>"
TEARDOWN_HELPER="$REPO_DIR/scripts/moos_scoped_teardown.sh"
RESULTS_FILE="$HARNESS_DIR/results.txt"
RUN_ROOT="$HARNESS_DIR/.harness_runs"
LOCK_DIR="$HARNESS_DIR/.harness_runs.lock"

TIME_WARP=10
MAX_TIME=90
JOBS=1
PORT_BASE=9000
PORT_STRIDE=30
PSHARE_OFFSET=$((PORT_STRIDE / 2))
KEEP_WORKDIRS=no
VERBOSE=
JUST_MAKE=no
DISPLAY_ARGS=(--nogui)
CASE=

# Customize this matrix plus apply_case_overlays below.
CASES=(baseline_pass blocked_fail)

declare -A PID_CASE PID_WORKDIR PID_RESULT PID_LOG PID_PORT_BASE
HAVE_LOCK=no

usage() {
  local case_name
  cat <<EOF
$ME [OPTIONS] [time_warp]

Options:
  --help, -h         Show this help message
  --verbose, -v      Verbose scheduler output
  --just_make, -j    Forward --just_make to stem launchers
  --max_time=<secs>  Max time forwarded to each stem mission
  --case=<name>      Run one named case
  --jobs=<n>         Run up to n cases concurrently with rolling scheduling
  --port_base=<n>    Base MOOS port for per-case blocks
  --keep_workdirs    Keep generated case work directories
  --gui              Launch with pMarineViewer
  --nogui, -ng       Headless launch, no gui (default)

Cases:
EOF
  for case_name in "${CASES[@]}"; do
    printf '  %s\n' "$case_name"
  done
  cat <<EOF

Examples:
  ./$ME
  ./$ME --case=${CASES[0]}
  ./$ME --jobs=4 --port_base=9600
EOF
}

die() {
  echo "$ME: $*" >&2
  exit 2
}

is_uint() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

for arg in "$@"; do
  case "$arg" in
    --case=*) CASE="${arg#--case=}" ;;
    --jobs=*) JOBS="${arg#--jobs=}" ;;
    --port_base=*) PORT_BASE="${arg#--port_base=}" ;;
    --max_time=*) MAX_TIME="${arg#--max_time=}" ;;
    --keep_workdirs) KEEP_WORKDIRS=yes ;;
    --verbose|-v) VERBOSE=yes ;;
    --just_make|-j) JUST_MAKE=yes ;;
    --gui) DISPLAY_ARGS=() ;;
    --nogui|-ng) DISPLAY_ARGS=(--nogui) ;;
    --help|-h) usage; exit 0 ;;
    *[!0-9]*|'') die "bad argument: $arg" ;;
    *) TIME_WARP="$arg" ;;
  esac
done

is_uint "$JOBS" && [ "$JOBS" -gt 0 ] || die "--jobs must be a positive integer"
is_uint "$PORT_BASE" || die "--port_base must be an integer"
is_uint "$MAX_TIME" || die "--max_time must be an integer"

[ -f "$TEARDOWN_HELPER" ] || { echo "$ME: missing teardown helper: $TEARDOWN_HELPER" >&2; exit 1; }
# shellcheck source=/dev/null
. "$TEARDOWN_HELPER"

select_cases() {
  SELECTED_CASES=()
  local case_name
  if [ -n "$CASE" ]; then
    for case_name in "${CASES[@]}"; do
      [ "$case_name" = "$CASE" ] && { SELECTED_CASES=("$case_name"); return 0; }
    done
    die "unknown case: $CASE"
  fi
  SELECTED_CASES=("${CASES[@]}")
  [ "${#SELECTED_CASES[@]}" -gt 0 ] || die "no cases selected"
}

grade_from_line() {
  local field
  for field in $1; do
    case "$field" in grade=*) printf '%s\n' "${field#grade=}"; return 0 ;; esac
  done
  return 1
}

stop_root() {
  moos_scoped_teardown_stop_root "$1" >/dev/null 2>&1 || true
}

cleanup() {
  local pid
  for pid in "${!PID_CASE[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
  [ -d "$RUN_ROOT" ] && stop_root "$RUN_ROOT"
  [ "$KEEP_WORKDIRS" = yes ] || rm -rf "$RUN_ROOT"
  [ "$HAVE_LOCK" = yes ] && rmdir "$LOCK_DIR" 2>/dev/null || true
}

on_signal() {
  cleanup
  exit 130
}

trap cleanup EXIT
trap on_signal INT TERM

apply_case_overlays() {
  local case_name="$1"
  local workdir="$2"
  case "$case_name" in
    baseline_pass)
      ;;
    blocked_fail)
      nspatch --stem="$workdir/meta_shoreside.moos" \
        "$HARNESS_DIR/blocked-shoreside.xmoos" \
        --targ="$workdir/meta_shoreside.moosx"
      ;;
    *)
      return 1
      ;;
  esac
}

prepare_case() {
  local case_name="$1"
  local workdir="$2"
  rm -rf "$workdir"
  mkdir -p "$workdir"
  cp -R "$MISSION_DIR"/. "$workdir"/
  apply_case_overlays "$case_name" "$workdir"
}

write_result() {
  local case_name="$1"
  local result_file="$2"
  local launch_rc="$3"
  local workdir="$4"
  local line
  if [ -f "$workdir/results.txt" ]; then
    line=$(awk 'NF {last=$0} END {print last}' "$workdir/results.txt")
    if grade_from_line "$line" >/dev/null 2>&1; then
      echo "case=$case_name $line" > "$result_file"
    else
      echo "case=$case_name grade=fail reason=missing_result" > "$result_file"
    fi
  elif [ "$launch_rc" -ne 0 ]; then
    echo "case=$case_name grade=fail reason=launch_error launch_rc=$launch_rc" > "$result_file"
  else
    echo "case=$case_name grade=fail reason=missing_result_file" > "$result_file"
  fi
}

run_case() {
  local case_name="$1"
  local case_idx="$2"
  local workdir="$3"
  local result_file="$4"
  local case_base="$5"
  local launch_rc=0
  local launch_args=()
  prepare_case "$case_name" "$workdir" || {
    echo "case=$case_name grade=fail reason=prepare_error" > "$result_file"
    return 1
  }

  (
    cd "$workdir" || exit 1
    : > results.txt
    launch_args=(
      --max_time="$MAX_TIME"
      "${DISPLAY_ARGS[@]}"
      --shore_mport="$((case_base + 0))"
      --veh_mport="$((case_base + 1))"
      --shore_pshare="$((case_base + PSHARE_OFFSET))"
      --veh_pshare="$((case_base + PSHARE_OFFSET + 1))"
      "$TIME_WARP"
    )
    [ "$JUST_MAKE" = yes ] && launch_args+=(--just_make)
    ./zlaunch.sh "${launch_args[@]}"
  ) || launch_rc=$?

  write_result "$case_name" "$result_file" "$launch_rc" "$workdir"
  stop_root "$workdir"
  [ "$(grade_from_line "$(cat "$result_file")" || true)" = pass ]
}

start_case() {
  local case_idx="$1"
  local case_name="${SELECTED_CASES[$case_idx]}"
  local case_dir="$RUN_ROOT/case_$(printf '%03d' "$case_idx")_$case_name"
  local workdir="$case_dir/mission"
  local result_file="$case_dir/result.row"
  local log_file="$case_dir/run.log"
  local case_base=$((PORT_BASE + case_idx * PORT_STRIDE))
  mkdir -p "$case_dir"
  (
    set +e
    run_case "$case_name" "$case_idx" "$workdir" "$result_file" "$case_base" > "$log_file" 2>&1
    rc=$?
    [ -s "$result_file" ] || echo "case=$case_name grade=fail reason=missing_result launch_rc=$rc" > "$result_file"
    exit "$rc"
  ) &

  local pid=$!
  PID_CASE[$pid]="$case_name"
  PID_WORKDIR[$pid]="$workdir"
  PID_RESULT[$pid]="$result_file"
  PID_LOG[$pid]="$log_file"
  PID_PORT_BASE[$pid]="$case_base"
  [ "$VERBOSE" = yes ] && printf 'start pid=%s case=%s port_base=%s workdir=%s\n' "$pid" "$case_name" "$case_base" "$workdir"
}

finish_one() {
  local done_pid=""
  local wait_rc=0
  local case_name line grade
  wait -p done_pid -n || wait_rc=$?
  if [ -z "${done_pid:-}" ]; then
    echo "$ME: wait returned without a completed pid rc=$wait_rc" >&2
    return 1
  fi
  case_name="${PID_CASE[$done_pid]:-}"
  [ -n "$case_name" ] || { echo "$ME: unknown completed pid '$done_pid' rc=$wait_rc" >&2; return 1; }

  line=$(awk 'NF {last=$0} END {print last}' "${PID_RESULT[$done_pid]}" 2>/dev/null)
  [ -n "$line" ] || line="case=$case_name grade=fail reason=missing_result_file"
  grade=$(grade_from_line "$line" || true)
  printf '%s\n' "$line" >> "$RESULTS_FILE"
  [ "$VERBOSE" = yes ] && printf 'finish pid=%s case=%s rc=%s grade=%s port_base=%s log=%s\n' \
    "$done_pid" "$case_name" "$wait_rc" "${grade:-missing}" "${PID_PORT_BASE[$done_pid]}" "${PID_LOG[$done_pid]}"

  unset 'PID_CASE[$done_pid]' 'PID_WORKDIR[$done_pid]' 'PID_RESULT[$done_pid]' 'PID_LOG[$done_pid]' 'PID_PORT_BASE[$done_pid]'
  [ "$grade" = pass ]
}

select_cases
mkdir "$LOCK_DIR" 2>/dev/null || die "another harness run appears active for $HARNESS_DIR"
HAVE_LOCK=yes
rm -rf "$RUN_ROOT"
mkdir -p "$RUN_ROOT"
: > "$RESULTS_FILE"

active=0
next=0
total=${#SELECTED_CASES[@]}
failures=0
result_rows=0
while [ "$next" -lt "$total" ] || [ "$active" -gt 0 ]; do
  while [ "$next" -lt "$total" ] && [ "$active" -lt "$JOBS" ]; do
    start_case "$next"
    next=$((next + 1))
    active=$((active + 1))
  done
  if [ "$active" -gt 0 ]; then
    finish_one || failures=$((failures + 1))
    result_rows=$((result_rows + 1))
    active=$((active - 1))
  fi
done

trap - EXIT INT TERM
stop_root "$RUN_ROOT"
[ "$KEEP_WORKDIRS" = yes ] || rm -rf "$RUN_ROOT"
rmdir "$LOCK_DIR" 2>/dev/null || true
HAVE_LOCK=no

if [ "$result_rows" -ne "$total" ]; then
  echo "$ME: expected $total result rows but wrote $result_rows" >&2
  exit 1
fi

echo "results=$RESULTS_FILE failures=$failures total=$total jobs=$JOBS bash=$BASH_VERSION"
# All selected cases have written rows by this point. Return nonzero only as
# the final CI verdict when one or more rows did not report grade=pass.
[ "$failures" -eq 0 ]
```

The stem mission should make `grade=pass` mean "this case behaved as intended."
For an expected-negative case, patch `pMissionEval` so the expected negative
evidence produces `grade=pass`; do not make the harness compare
`expected=fail actual=fail`.

Setup errors, including unknown cases, missing patch files, launch script
failures, and missing `grade=`, should emit `case=<case> grade=fail
reason=<runner_reason>`. The harness should finish all selected cases, publish
one row per selected case, and only then return a nonzero CI verdict if any row
did not report `grade=pass`.

Generated harness repositories should include the helper asset at
`<project-root>/scripts/moos_scoped_teardown.sh`. Source it once near startup,
call `moos_scoped_teardown_stop_root` through a small wrapper, and use that
wrapper after each case plus in the exit cleanup trap.
