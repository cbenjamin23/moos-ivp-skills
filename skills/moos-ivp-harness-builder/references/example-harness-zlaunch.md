# Example Harness `zlaunch.sh` Skeleton

This is an architecture sketch, not a complete drop-in script. Use it to keep
the responsibilities in the right place, then add the full argument parsing,
wave mechanics, cleanup traps, and self-tests described in the other references.

```bash
#!/bin/bash
set -u

ME=`basename "$0"`
HARNESS_DIR="$(cd "$(dirname "$0")" && pwd)"
MISSION_DIR="$HARNESS_DIR/../../missions/example_eval"
RESULTS_FILE="$HARNESS_DIR/results.txt"
TIME_WARP=10
MAX_TIME=90
CASE=""
JOBS=1
PORT_BASE=9000
PORT_STRIDE=30
PSHARE_OFFSET=$((PORT_STRIDE / 2))
KEEP_WORKDIRS="no"
NOGUI="--nogui"

CASES=(baseline_pass blocked_fail)

get_case_config() {
  NO_PATCH="no"
  SHORE_PATCH=""
  VEH_MOOS_PATCH=""
  VEH_BHV_PATCH=""
  case "$1" in
    baseline_pass)
      NO_PATCH="yes"
      ;;
    blocked_fail)
      SHORE_PATCH="$HARNESS_DIR/blocked-shoreside.xmoos"
      VEH_MOOS_PATCH="$HARNESS_DIR/blocked-vehicle.xmoos"
      VEH_BHV_PATCH="$HARNESS_DIR/blocked-vehicle.xbhv"
      ;;
    *)
      echo "$ME: Unknown case: $1"
      return 1
      ;;
  esac
}

apply_case_patches() {
  local workdir="$1"
  local shore_stem="$workdir/meta_shoreside.moos"
  local shore_xfile="$workdir/meta_shoreside.moosx"
  local veh_stem="$workdir/meta_vehicle.moos"
  local veh_xfile="$workdir/meta_vehicle.moosx"
  local bhv_stem="$workdir/meta_vehicle.bhv"
  local bhv_xfile="$workdir/meta_vehicle.bhvx"

  rm -f "$shore_xfile" "$veh_xfile" "$bhv_xfile"

  if [ "$NO_PATCH" = "yes" ]; then
    return 0
  fi

  for patch in "$SHORE_PATCH" "$VEH_MOOS_PATCH" "$VEH_BHV_PATCH"; do
    if [ "$patch" != "" ] && [ ! -f "$patch" ]; then
      echo "$ME: Missing declared patch: $patch"
      return 1
    fi
  done

  if [ "$SHORE_PATCH" != "" ]; then
    nspatch --stem="$shore_stem" "$SHORE_PATCH" --targ="$shore_xfile"
  fi
  if [ "$VEH_MOOS_PATCH" != "" ]; then
    nspatch --stem="$veh_stem" "$VEH_MOOS_PATCH" --targ="$veh_xfile"
  fi
  if [ "$VEH_BHV_PATCH" != "" ]; then
    nspatch --stem="$bhv_stem" "$VEH_BHV_PATCH" --targ="$bhv_xfile"
  fi
}

grade_from_line() {
  local line="$1"
  awk '{
    for (i=1; i<=NF; i++) {
      if ($i ~ /^grade=/) {
        sub(/^grade=/, "", $i)
        print $i
        exit
      }
    }
  }' <<< "$line"
}

format_result_row() {
  local case_name="$1"
  local results_file="$2"
  local launch_rc="$3"
  local line
  local grade

  if [ "$launch_rc" -ne 0 ]; then
    echo "case=$case_name grade=fail reason=launch_error launch_rc=$launch_rc"
    return
  fi

  if [ ! -f "$results_file" ]; then
    echo "case=$case_name grade=fail reason=missing_result_file"
    return
  fi

  line="$(awk 'NF {last=$0} END {print last}' "$results_file")"
  grade="$(grade_from_line "$line")"
  if [ "$grade" = "" ]; then
    echo "case=$case_name grade=fail reason=missing_result"
    return
  fi

  echo "case=$case_name $line"
}

case_passed() {
  local line="$1"
  [ "$(grade_from_line "$line")" = "pass" ]
}

run_case() {
  local case_name="$1"
  local case_idx="$2"
  local workdir="$3"
  local case_base=$((PORT_BASE + case_idx * PORT_STRIDE))
  local shore_mport=$((case_base + 0))
  local veh_mport=$((case_base + 1))
  local shore_pshare=$((case_base + PSHARE_OFFSET))
  local veh_pshare=$((case_base + PSHARE_OFFSET + 1))

  get_case_config "$case_name" || return 1
  if ! apply_case_patches "$workdir"; then
    echo "case=$case_name grade=fail reason=prepare_error"
    return 1
  fi

  local launch_rc=0
  (
    cd "$workdir" || exit 1
    : > results.txt
    ./zlaunch.sh --max_time="$MAX_TIME" $NOGUI --mmod="$case_name" \
      --shore_mport="$shore_mport" --veh_mport="$veh_mport" \
      --shore_pshare="$shore_pshare" --veh_pshare="$veh_pshare" \
      "$TIME_WARP"
  ) || launch_rc=$?

  local result_line
  result_line="$(format_result_row "$case_name" "$workdir/results.txt" "$launch_rc")"
  echo "$result_line"
  case_passed "$result_line"
}
```

The stem mission should make `grade=pass` mean "this case behaved as intended."
For an expected-negative case, patch `pMissionEval` so the expected negative
evidence produces `grade=pass`; do not make the harness compare
`expected=fail actual=fail`.

Setup errors, including unknown cases, missing patch files, launch script
failures, and missing `grade=`, should emit `case=<case> grade=fail
reason=<runner_reason>`. Full harnesses should add robust argument parsing,
temp-copy creation, wave barriers, cleanup traps, README/script case
reconciliation, target-port inspection, and `--keep_workdirs`.
