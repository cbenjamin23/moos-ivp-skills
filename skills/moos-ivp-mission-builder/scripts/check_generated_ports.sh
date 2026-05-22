#!/bin/bash
set -u

MISSION_DIR="."
PORT_BASE=9100
KEEP_TARGETS="no"
STATUS=0

usage() {
  cat <<'EOF'
Usage:
  check_generated_ports.sh [mission-dir] [--port_base=N] [--keep-targets]

Options:
  --port_base=N   Base MOOSDB port for generated target checks.
                  pShare ports use N+200. Default: 9100.
  --keep-targets  Preserve generated targ_* files after the check.
  -h, --help      Show this help.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --port_base=*)
      PORT_BASE="${arg#*=}"
      ;;
    --keep-targets)
      KEEP_TARGETS="yes"
      ;;
    -*)
      echo "unknown option: $arg" >&2
      usage >&2
      exit 2
      ;;
    *)
      MISSION_DIR="$arg"
      ;;
  esac
done

case "$PORT_BASE" in
  ''|*[!0-9]*)
    echo "invalid --port_base: $PORT_BASE" >&2
    exit 2
    ;;
esac

SHORE_MPORT=$PORT_BASE
VEH_MPORT=$((PORT_BASE + 1))
BRAVO_MPORT=$((PORT_BASE + 2))
SHORE_PSHARE=$((PORT_BASE + 200))
VEH_PSHARE=$((PORT_BASE + 201))
BRAVO_PSHARE=$((PORT_BASE + 202))

cd "$MISSION_DIR" || exit 2
if [ "$KEEP_TARGETS" != "yes" ]; then
  trap './clean.sh >/dev/null 2>&1 || true' EXIT
fi

if [ ! -x "./launch.sh" ]; then
  echo "missing executable launch.sh"
  exit 1
fi

./clean.sh >/dev/null 2>&1 || true

ARGS=(--just_make --nogui --shore_mport="$SHORE_MPORT" --shore_pshare="$SHORE_PSHARE" 7)
CHECK_MODE="shoreside"

HELP="$(./launch.sh --help 2>&1 || true)"
if echo "$HELP" | grep -q -- '--alpha_mport' && \
   echo "$HELP" | grep -q -- '--bravo_mport'; then
  ARGS=(--just_make --nogui --shore_mport="$SHORE_MPORT" --shore_pshare="$SHORE_PSHARE")
  ARGS+=(--alpha_mport="$VEH_MPORT" --alpha_pshare="$VEH_PSHARE")
  ARGS+=(--bravo_mport="$BRAVO_MPORT" --bravo_pshare="$BRAVO_PSHARE" 7)
  CHECK_MODE="alpha_bravo"
elif echo "$HELP" | grep -q -- '--veh_mport'; then
  ARGS=(--just_make --nogui --shore_mport="$SHORE_MPORT" --veh_mport="$VEH_MPORT" --shore_pshare="$SHORE_PSHARE" --veh_pshare="$VEH_PSHARE" 7)
  CHECK_MODE="single_vehicle"
elif echo "$HELP" | grep -q -- '--alpha_mport'; then
  ARGS=(--just_make --nogui --shore_mport="$SHORE_MPORT" --alpha_mport="$VEH_MPORT" --shore_pshare="$SHORE_PSHARE" --alpha_pshare="$VEH_PSHARE" 7)
  CHECK_MODE="single_vehicle"
fi

if ! ./launch.sh "${ARGS[@]}" >/tmp/moos_ivp_generated_ports.$$ 2>&1; then
  cat /tmp/moos_ivp_generated_ports.$$
  rm -f /tmp/moos_ivp_generated_ports.$$
  exit 1
fi
rm -f /tmp/moos_ivp_generated_ports.$$

if [ ! -f targ_shoreside.moos ]; then
  echo "missing generated targ_shoreside.moos"
  STATUS=1
else
  grep -q "ServerPort *= *$SHORE_MPORT" targ_shoreside.moos || {
    echo "targ_shoreside.moos: expected ServerPort $SHORE_MPORT"; STATUS=1; }
  grep -q "input *= *route *= *localhost:$SHORE_PSHARE" targ_shoreside.moos || {
    echo "targ_shoreside.moos: expected pShare route localhost:$SHORE_PSHARE"; STATUS=1; }
fi

check_vehicle_target() {
  local target="$1"
  local mport="$2"
  local pshare="$3"
  local label="$4"

  if [ ! -f "$target" ]; then
    echo "missing generated $target"
    STATUS=1
    return
  fi

  grep -q "ServerPort *= *$mport" "$target" || {
    echo "$target: expected $label ServerPort $mport"; STATUS=1; }
  grep -q "input *= *route *= *localhost:$pshare" "$target" || {
    echo "$target: expected $label pShare route localhost:$pshare"; STATUS=1; }
  grep -q "try_shore_host *= *pshare_route=.*:$SHORE_PSHARE" "$target" || {
    echo "$target: expected $label broker route to shoreside pShare $SHORE_PSHARE"; STATUS=1; }
}

if [ "$CHECK_MODE" = "alpha_bravo" ]; then
  check_vehicle_target targ_alpha.moos "$VEH_MPORT" "$VEH_PSHARE" alpha
  check_vehicle_target targ_bravo.moos "$BRAVO_MPORT" "$BRAVO_PSHARE" bravo
elif [ "$CHECK_MODE" = "single_vehicle" ]; then
  VEH_TARGET="$(ls targ_*.moos 2>/dev/null | grep -v 'targ_shoreside.moos' | head -1 || true)"
  if [ "$VEH_TARGET" != "" ]; then
    check_vehicle_target "$VEH_TARGET" "$VEH_MPORT" "$VEH_PSHARE" "first vehicle"
  fi
fi

if [ "$STATUS" -eq 0 ]; then
  echo "PASS generated targets use requested non-default ports: mode=$CHECK_MODE shore_mport=$SHORE_MPORT shore_pshare=$SHORE_PSHARE keep_targets=$KEEP_TARGETS"
fi

exit "$STATUS"
