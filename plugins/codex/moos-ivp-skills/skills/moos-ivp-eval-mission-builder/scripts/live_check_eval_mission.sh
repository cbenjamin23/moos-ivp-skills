#!/usr/bin/env bash
set -u

MISSION_DIR="${1:-.}"
PORT_BASE=9700
MAX_TIME=45
TIME_WARP=10
EXPECTED_GRADE="pass"
FAIL_ON_BHV_WARNING="no"
KEEP_WORKDIR="no"
STATUS=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEARDOWN_HELPER="$SCRIPT_DIR/../assets/moos_scoped_teardown.sh"

usage() {
  cat <<'EOF'
Usage:
  live_check_eval_mission.sh <mission-dir> [OPTIONS]

Options:
  --port_base=N          Shoreside MOOSDB port. Vehicle uses N+1.
                         pShare ports use N+200 and N+201. Default: 9700.
  --max_time=N           Max time forwarded to zlaunch.sh. Default: 45.
  --time_warp=N          Time warp passed to zlaunch.sh. Default: 10.
  --expected_grade=VAL   Expected final grade value. Default: pass.
  --fail_on_bhv_warning  Fail when logs/results show BHV warning evidence.
  --allow_bhv_warning    Accepted for compatibility; warnings are advisory by default.
  --keep-workdir         Preserve the temp mission copy for inspection.
  -h, --help             Show this help.
EOF
}

shift_if_mission_arg() {
  case "${1:-}" in
    ""|-*)
      ;;
    *)
      MISSION_DIR="$1"
      shift
      ;;
  esac
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      --port_base=*)
        PORT_BASE="${1#*=}"
        ;;
      --max_time=*)
        MAX_TIME="${1#*=}"
        ;;
      --time_warp=*)
        TIME_WARP="${1#*=}"
        ;;
      --expected_grade=*)
        EXPECTED_GRADE="${1#*=}"
        ;;
      --fail_on_bhv_warning|--fail-on-bhv-warning)
        FAIL_ON_BHV_WARNING="yes"
        ;;
      --allow_bhv_warning|--allow-bhv-warning)
        FAIL_ON_BHV_WARNING="no"
        ;;
      --keep-workdir|--keep_workdir)
        KEEP_WORKDIR="yes"
        ;;
      *)
        echo "unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

is_uint() {
  case "$1" in
    ""|*[!0-9]*)
      return 1
      ;;
  esac
  return 0
}

port_pids() {
  lsof -tiTCP:"$SHORE_MPORT" -tiTCP:"$VEH_MPORT" \
       -tiTCP:"$SHORE_PSHARE" -tiTCP:"$VEH_PSHARE" \
       -sTCP:LISTEN 2>/dev/null | sort -u
}

# shellcheck disable=SC2329
cleanup_leftovers() {
  local pids
  if [ "${WORKDIR:-}" != "" ] && [ -d "$WORKDIR" ] && [ -f "$TEARDOWN_HELPER" ]; then
    # xlaunch.sh may only signal its direct children; ANTLER-launched apps can
    # reparent. Use the same root-scoped helper recommended for harnesses.
    # shellcheck disable=SC1090
    . "$TEARDOWN_HELPER"
    moos_scoped_teardown_stop_root "$WORKDIR" >/dev/null 2>&1 || true
  fi
  pids="$(port_pids)"
  if [ "$pids" != "" ]; then
    # shellcheck disable=SC2086
    kill $pids 2>/dev/null || true
    sleep 1
  fi
  pids="$(port_pids)"
  if [ "$pids" != "" ]; then
    # shellcheck disable=SC2086
    kill -9 $pids 2>/dev/null || true
  fi
  if [ "$KEEP_WORKDIR" != "yes" ] && [ "${TMP_ROOT:-}" != "" ] && [ -d "$TMP_ROOT" ]; then
    rm -rf "$TMP_ROOT"
  fi
}

fail() {
  echo "FAIL $*"
  STATUS=1
}

shift_if_mission_arg "$@"

if ! is_uint "$PORT_BASE" || ! is_uint "$MAX_TIME" || ! is_uint "$TIME_WARP"; then
  echo "port_base, max_time, and time_warp must be unsigned integers" >&2
  exit 2
fi

SHORE_MPORT=$PORT_BASE
VEH_MPORT=$((PORT_BASE + 1))
SHORE_PSHARE=$((PORT_BASE + 200))
VEH_PSHARE=$((PORT_BASE + 201))

if [ ! -d "$MISSION_DIR" ]; then
  echo "missing mission directory: $MISSION_DIR" >&2
  exit 2
fi
if [ ! -x "$MISSION_DIR/zlaunch.sh" ]; then
  echo "mission directory must contain executable zlaunch.sh: $MISSION_DIR" >&2
  exit 2
fi
if [ ! -f "$TEARDOWN_HELPER" ]; then
  echo "missing bundled teardown helper: $TEARDOWN_HELPER" >&2
  exit 2
fi

if [ "$(port_pids)" != "" ]; then
  echo "requested ports are already in use: $SHORE_MPORT $VEH_MPORT $SHORE_PSHARE $VEH_PSHARE" >&2
  exit 2
fi

TMP_ROOT="$(mktemp -d /tmp/moos_eval_live_check.XXXXXX)"
trap cleanup_leftovers EXIT
cp -R "$MISSION_DIR" "$TMP_ROOT/mission"
mkdir -p "$TMP_ROOT/scripts"
cp "$TEARDOWN_HELPER" "$TMP_ROOT/scripts/moos_scoped_teardown.sh"
chmod +x "$TMP_ROOT/scripts/moos_scoped_teardown.sh"
WORKDIR="$TMP_ROOT/mission"
chmod +x "$WORKDIR"/*.sh 2>/dev/null || true

(
  cd "$WORKDIR" || exit 2
  ./zlaunch.sh --nogui --max_time="$MAX_TIME" \
    --shore_mport="$SHORE_MPORT" --veh_mport="$VEH_MPORT" \
    --shore_pshare="$SHORE_PSHARE" --veh_pshare="$VEH_PSHARE" \
    "$TIME_WARP"
) >"$TMP_ROOT/zlaunch.out" 2>&1
LAUNCH_RC=$?

if [ "$LAUNCH_RC" -ne 0 ]; then
  fail "zlaunch.sh exited $LAUNCH_RC"
fi

RESULT_LINE=""
if [ -f "$WORKDIR/results.txt" ]; then
  RESULT_LINE="$(awk 'NF {last=$0} END {print last}' "$WORKDIR/results.txt")"
else
  fail "missing results.txt"
fi

if [ "$RESULT_LINE" = "" ]; then
  fail "missing non-empty result line"
elif ! printf '%s\n' "$RESULT_LINE" | grep -Eq '(^|[[:space:]])grade='; then
  fail "result line has no grade=: $RESULT_LINE"
else
  GRADE="$(printf '%s\n' "$RESULT_LINE" | awk '{
    for (i=1; i<=NF; i++) {
      if ($i ~ /^grade=/) {
        sub(/^grade=/, "", $i)
        print $i
        exit
      }
    }
  }')"
  if [ "$GRADE" != "$EXPECTED_GRADE" ]; then
    fail "expected grade=$EXPECTED_GRADE but saw grade=$GRADE"
  fi
fi

WARNING_EVIDENCE=""
if printf '%s\n' "$RESULT_LINE" | grep -Eq '(^|[[:space:]])bhv_warning=true([^[:alnum:]_]|$)'; then
  WARNING_EVIDENCE="result reports bhv_warning=true"
fi
if find "$WORKDIR" -type f -name '*.alog' -print0 |
   xargs -0 grep -E 'BHV_WARNING[[:space:]]+pHelmIvP|BHV_WARNING_SEEN[[:space:]]+pMissionEval[[:space:]]+true' >/dev/null 2>&1; then
  if [ "$WARNING_EVIDENCE" != "" ]; then
    WARNING_EVIDENCE="$WARNING_EVIDENCE; logs contain BHV_WARNING evidence"
  else
    WARNING_EVIDENCE="logs contain BHV_WARNING evidence"
  fi
fi
if [ "$WARNING_EVIDENCE" != "" ]; then
  if [ "$FAIL_ON_BHV_WARNING" = "yes" ]; then
    fail "$WARNING_EVIDENCE"
  else
    echo "WARN $WARNING_EVIDENCE"
  fi
fi

LEFTOVER_PIDS="$(port_pids)"
if [ "$LEFTOVER_PIDS" != "" ]; then
  fail "leftover listeners on checked ports: $LEFTOVER_PIDS"
fi

if [ "$STATUS" -eq 0 ]; then
  echo "PASS live eval check: grade=$EXPECTED_GRADE ports=$SHORE_MPORT/$VEH_MPORT/$SHORE_PSHARE/$VEH_PSHARE workdir=$WORKDIR"
else
  echo "zlaunch output: $TMP_ROOT/zlaunch.out"
  if [ "$RESULT_LINE" != "" ]; then
    echo "result: $RESULT_LINE"
  fi
  if [ "$KEEP_WORKDIR" != "yes" ]; then
    echo "temp workdir will be removed after cleanup"
  else
    echo "temp workdir preserved: $WORKDIR"
  fi
fi

exit "$STATUS"
