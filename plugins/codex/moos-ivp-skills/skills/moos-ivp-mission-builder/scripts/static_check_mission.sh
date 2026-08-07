#!/bin/bash
set -u

MISSION_DIR="${1:-.}"
STATUS=0

need_file() {
  if [ ! -f "$MISSION_DIR/$1" ]; then
    echo "missing: $1"
    STATUS=1
  fi
}

need_grep() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  if [ -f "$MISSION_DIR/$file" ] && ! grep -Eq -- "$pattern" "$MISSION_DIR/$file"; then
    echo "$file: $message"
    STATUS=1
  fi
}

reject_grep() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  if [ -f "$MISSION_DIR/$file" ] && grep -Eq -- "$pattern" "$MISSION_DIR/$file"; then
    echo "$file: $message"
    STATUS=1
  fi
}

need_file launch.sh
need_file clean.sh
need_file launch_shoreside.sh
need_file meta_shoreside.moos
need_file README.md

HAS_VEHICLE="no"
if [ -f "$MISSION_DIR/launch_vehicle.sh" ] || \
   [ -f "$MISSION_DIR/meta_vehicle.moos" ] || \
   [ -f "$MISSION_DIR/meta_vehicle.bhv" ]; then
  HAS_VEHICLE="yes"
fi

if [ "$HAS_VEHICLE" = "yes" ]; then
  need_file launch_vehicle.sh
  need_file meta_vehicle.moos
  need_file meta_vehicle.bhv
fi

need_grep '--just_make' launch.sh "expected --just_make support"
need_grep '--nogui' launch.sh "expected --nogui support"
need_grep '--shore_mport' launch.sh "expected shoreside MOOSDB port override"
if [ "$HAS_VEHICLE" = "yes" ]; then
  need_grep '--veh_mport|--[[:alnum:]_]+_mport' launch.sh "expected vehicle MOOSDB port override"
  need_grep 'nsplug ' launch_vehicle.sh "expected nsplug target generation"
  need_grep 'NSFLAGS=.*--strict.*--force.*-x|nsplug .*--strict.*--force.*-x' launch_vehicle.sh "expected strict nsplug generation with force and sidecar support"
  reject_grep '--interactive' launch_vehicle.sh "expected strict nsplug generation for direct and automated launches"
fi
need_grep 'nsplug ' launch_shoreside.sh "expected nsplug target generation"
need_grep 'NSFLAGS=.*--strict.*--force.*-x|nsplug .*--strict.*--force.*-x' launch_shoreside.sh "expected strict nsplug generation with force and sidecar support"
reject_grep '--interactive' launch_shoreside.sh "expected strict nsplug generation for direct and automated launches"
if [ "$HAS_VEHICLE" = "yes" ]; then
  need_grep 'ProcessConfig *= *pHelmIvP' meta_vehicle.moos "expected pHelmIvP block"
  need_grep 'behaviors *= *targ_.*\.bhv' meta_vehicle.moos "expected generated behavior file"
  need_grep '^ServerHost[[:space:]]*=[[:space:]]*localhost[[:space:]]*$' meta_vehicle.moos "expected local MOOSDB connection"
  need_grep 'default_hostip_force[[:space:]]*=[[:space:]]*\$\(IP_ADDR=localhost\)' meta_vehicle.moos "expected --ip to force the advertised pHostInfo address"
  need_grep 'input *= *route *= *[^ :]+:\$\(PSHARE_PORT\)' meta_vehicle.moos "expected vehicle pShare to use PSHARE_PORT"
  need_grep 'Behavior *= *BHV_' meta_vehicle.bhv "expected at least one behavior block"
fi
need_grep 'ProcessConfig *= *pMarineViewer' meta_shoreside.moos "expected pMarineViewer block"
need_grep '^ServerHost[[:space:]]*=[[:space:]]*localhost[[:space:]]*$' meta_shoreside.moos "expected local MOOSDB connection"
need_grep 'default_hostip_force[[:space:]]*=[[:space:]]*\$\(IP_ADDR=localhost\)' meta_shoreside.moos "expected --ip to force the advertised pHostInfo address"
need_grep 'input *= *route *= *[^ :]+:\$\(PSHARE_PORT\)' meta_shoreside.moos "expected shoreside pShare to use PSHARE_PORT"

if grep -R --include='*.sh' -Eq '\\b(ktm|pkill)\\b' "$MISSION_DIR"; then
  echo "warning: launcher contains ktm or pkill; ordinary mission cleanup should avoid global process kills"
fi

if grep -R --include='*.sh' -Eq '(^|[[:space:]])setsid([[:space:]]|$)' "$MISSION_DIR" &&
   ! grep -R --include='*.sh' -Eq 'command[[:space:]]+-v[[:space:]]+setsid|type[[:space:]]+-P[[:space:]]+setsid' "$MISSION_DIR"; then
  echo "warning: launcher uses setsid without an availability check; provide a portable fallback or document a Linux-only runtime"
fi

if [ -f "$MISSION_DIR/stop.sh" ] &&
   grep -Eq '/proc/' "$MISSION_DIR/stop.sh" &&
   ! grep -Eq 'lsof|Darwin|uname' "$MISSION_DIR/stop.sh"; then
  echo "warning: stop.sh uses /proc without an obvious non-Linux fallback; use scoped PID records or lsof when portability is claimed"
fi

exit "$STATUS"
