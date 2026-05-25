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
SHORE_PSHARE=$((PORT_BASE + 200))

cd "$MISSION_DIR" || exit 2
if [ "$KEEP_TARGETS" != "yes" ]; then
  trap './clean.sh >/dev/null 2>&1 || true' EXIT
fi

if [ ! -x "./launch.sh" ]; then
  echo "missing executable launch.sh"
  exit 1
fi

./clean.sh >/dev/null 2>&1 || true

ARGS=(--just_make --nogui --shore_mport="$SHORE_MPORT" --shore_pshare="$SHORE_PSHARE")
CHECK_MODE="shoreside"

HELP="$(./launch.sh --help 2>&1 || true)"
VEH_NAMES=()
VEH_MPORTS=()
VEH_PSHARES=()

for opt in $(printf '%s\n' "$HELP" | grep -Eo -- '--[A-Za-z0-9_]+_mport' | sort -u); do
  name="${opt#--}"
  name="${name%_mport}"
  [ "$name" = "shore" ] && continue
  VEH_NAMES+=("$name")
done

if [ "${#VEH_NAMES[@]}" -gt 1 ]; then
  FILTERED_NAMES=()
  for name in "${VEH_NAMES[@]}"; do
    [ "$name" = "veh" ] && continue
    FILTERED_NAMES+=("$name")
  done
  VEH_NAMES=("${FILTERED_NAMES[@]}")
fi

idx=1
for name in "${VEH_NAMES[@]}"; do
  mport=$((PORT_BASE + idx))
  pshare=$((PORT_BASE + 200 + idx))
  ARGS+=("--${name}_mport=$mport")
  if printf '%s\n' "$HELP" | grep -q -- "--${name}_pshare"; then
    ARGS+=("--${name}_pshare=$pshare")
  else
    echo "launch.sh help advertises --${name}_mport but not --${name}_pshare"
    STATUS=1
  fi
  VEH_MPORTS+=("$mport")
  VEH_PSHARES+=("$pshare")
  idx=$((idx + 1))
done

ARGS+=(7)

if [ "${#VEH_NAMES[@]}" -eq 1 ]; then
  CHECK_MODE="single_vehicle:${VEH_NAMES[0]}"
elif [ "${#VEH_NAMES[@]}" -gt 1 ]; then
  CHECK_MODE="multi_vehicle:${#VEH_NAMES[@]}"
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

idx=0
for name in "${VEH_NAMES[@]}"; do
  target="targ_${name}.moos"
  if [ ! -f "$target" ] && [ "${#VEH_NAMES[@]}" -eq 1 ]; then
    first_target=""
    for candidate in targ_*.moos; do
      [ -e "$candidate" ] || continue
      [ "$candidate" = "targ_shoreside.moos" ] && continue
      first_target="$candidate"
      break
    done
    [ "$first_target" != "" ] && target="$first_target"
  fi
  check_vehicle_target "$target" "${VEH_MPORTS[$idx]}" "${VEH_PSHARES[$idx]}" "$name"
  idx=$((idx + 1))
done

if [ "$STATUS" -eq 0 ]; then
  echo "PASS generated targets use requested non-default ports: mode=$CHECK_MODE vehicles=${#VEH_NAMES[@]} shore_mport=$SHORE_MPORT shore_pshare=$SHORE_PSHARE keep_targets=$KEEP_TARGETS"
fi

exit "$STATUS"
