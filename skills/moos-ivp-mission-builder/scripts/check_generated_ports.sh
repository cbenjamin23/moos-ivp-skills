#!/bin/bash
set -u

MISSION_DIR="${1:-.}"
STATUS=0

cd "$MISSION_DIR" || exit 2
trap './clean.sh >/dev/null 2>&1 || true' EXIT

if [ ! -x "./launch.sh" ]; then
  echo "missing executable launch.sh"
  exit 1
fi

./clean.sh >/dev/null 2>&1 || true

ARGS=(--just_make --nogui --shore_mport=9100 --shore_pshare=9300 7)
CHECK_MODE="shoreside"

HELP="$(./launch.sh --help 2>&1 || true)"
if echo "$HELP" | grep -q -- '--alpha_mport' && \
   echo "$HELP" | grep -q -- '--bravo_mport'; then
  ARGS=(--just_make --nogui --shore_mport=9100 --shore_pshare=9300)
  ARGS+=(--alpha_mport=9101 --alpha_pshare=9301)
  ARGS+=(--bravo_mport=9102 --bravo_pshare=9302 7)
  CHECK_MODE="alpha_bravo"
elif echo "$HELP" | grep -q -- '--veh_mport'; then
  ARGS=(--just_make --nogui --shore_mport=9100 --veh_mport=9101 --shore_pshare=9300 --veh_pshare=9301 7)
  CHECK_MODE="single_vehicle"
elif echo "$HELP" | grep -q -- '--alpha_mport'; then
  ARGS=(--just_make --nogui --shore_mport=9100 --alpha_mport=9101 --shore_pshare=9300 --alpha_pshare=9301 7)
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
  grep -q 'ServerPort *= *9100' targ_shoreside.moos || {
    echo "targ_shoreside.moos: expected ServerPort 9100"; STATUS=1; }
  grep -q 'input *= *route *= *localhost:9300' targ_shoreside.moos || {
    echo "targ_shoreside.moos: expected pShare route localhost:9300"; STATUS=1; }
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
  grep -q 'try_shore_host *= *pshare_route=.*:9300' "$target" || {
    echo "$target: expected $label broker route to shoreside pShare 9300"; STATUS=1; }
}

if [ "$CHECK_MODE" = "alpha_bravo" ]; then
  check_vehicle_target targ_alpha.moos 9101 9301 alpha
  check_vehicle_target targ_bravo.moos 9102 9302 bravo
elif [ "$CHECK_MODE" = "single_vehicle" ]; then
  VEH_TARGET="$(ls targ_*.moos 2>/dev/null | grep -v 'targ_shoreside.moos' | head -1 || true)"
  if [ "$VEH_TARGET" != "" ]; then
    check_vehicle_target "$VEH_TARGET" 9101 9301 "first vehicle"
  fi
fi

if [ "$STATUS" -eq 0 ]; then
  echo "PASS generated targets use requested non-default ports; temporary targets will be cleaned on exit"
fi

exit "$STATUS"
