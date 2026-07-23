#!/bin/bash
set -u

MISSION_DIR="${1:-.}"
STATUS=0

SHORE_IP="192.0.2.10"
VEHICLE_IP="192.0.2.20"
SHORE_MPORT=9100
VEHICLE_MPORT=9101
SHORE_PSHARE=9300
VEHICLE_PSHARE=9301
VNAME="nettest"

if [ ! -d "$MISSION_DIR" ]; then
  echo "not a mission directory: $MISSION_DIR" >&2
  exit 2
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/moos_generated_networking.XXXXXX")" ||
  exit 2

# Invoked by the EXIT trap below.
# shellcheck disable=SC2329
cleanup() {
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

cp -R "$MISSION_DIR"/. "$WORK_DIR"/ || exit 2
cd "$WORK_DIR" || exit 2

for launcher in launch_shoreside.sh launch_vehicle.sh; do
  if [ ! -x "$launcher" ]; then
    echo "missing executable $launcher"
    exit 1
  fi
done

if ! ./launch_shoreside.sh --auto --just_make --nogui \
  --ip="$SHORE_IP" --mport="$SHORE_MPORT" --pshare="$SHORE_PSHARE" \
  --vnames="$VNAME" 7; then
  echo "shoreside target generation failed"
  exit 1
fi

if ! ./launch_vehicle.sh --auto --just_make \
  --ip="$VEHICLE_IP" --shore="$SHORE_IP" \
  --mport="$VEHICLE_MPORT" --pshare="$VEHICLE_PSHARE" \
  --shore_pshare="$SHORE_PSHARE" --vname="$VNAME" 7; then
  echo "vehicle target generation failed"
  exit 1
fi

need_generated() {
  local pattern="$1"
  local file="$2"
  local message="$3"

  if [ ! -f "$file" ]; then
    echo "missing generated $file"
    STATUS=1
  elif ! grep -Eq -- "$pattern" "$file"; then
    echo "$file: $message"
    STATUS=1
  fi
}

need_generated '^ServerHost[[:space:]]*=[[:space:]]*localhost[[:space:]]*$' \
  targ_shoreside.moos "expected ServerHost localhost"
need_generated "ServerPort[[:space:]]*=[[:space:]]*$SHORE_MPORT" \
  targ_shoreside.moos "expected requested shoreside MOOSDB port"
need_generated "default_hostip_force[[:space:]]*=[[:space:]]*$SHORE_IP" \
  targ_shoreside.moos "expected requested shoreside advertised address"
need_generated "input[[:space:]]*=[[:space:]]*route[[:space:]]*=[[:space:]]*localhost:$SHORE_PSHARE" \
  targ_shoreside.moos "expected requested shoreside pShare listener port"

need_generated '^ServerHost[[:space:]]*=[[:space:]]*localhost[[:space:]]*$' \
  "targ_${VNAME}.moos" "expected ServerHost localhost"
need_generated "ServerPort[[:space:]]*=[[:space:]]*$VEHICLE_MPORT" \
  "targ_${VNAME}.moos" "expected requested vehicle MOOSDB port"
need_generated "default_hostip_force[[:space:]]*=[[:space:]]*$VEHICLE_IP" \
  "targ_${VNAME}.moos" "expected requested vehicle advertised address"
need_generated "input[[:space:]]*=[[:space:]]*route[[:space:]]*=[[:space:]]*localhost:$VEHICLE_PSHARE" \
  "targ_${VNAME}.moos" "expected requested vehicle pShare listener port"
need_generated "try_shore_host[[:space:]]*=[[:space:]]*pshare_route=$SHORE_IP:$SHORE_PSHARE" \
  "targ_${VNAME}.moos" "expected requested vehicle-to-shoreside route"

if [ "$STATUS" -eq 0 ]; then
  echo "PASS generated targets preserve local MOOSDB connections and requested network identity"
fi

exit "$STATUS"
