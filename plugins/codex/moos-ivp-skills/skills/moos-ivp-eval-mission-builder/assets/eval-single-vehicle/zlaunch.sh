#!/bin/bash
#------------------------------------------------------------
#   Script: zlaunch.sh
#  Mission: eval-single-vehicle
#   Author: MOOS-IvP Skills
#------------------------------------------------------------
#  Part 1: Set convenience functions for terminal output.
#------------------------------------------------------------
vecho() { if [ "$VERBOSE" != "" ]; then echo "$ME: $1"; fi; }

find_teardown_helper() {
  local dir
  dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -x "$dir/scripts/moos_scoped_teardown.sh" ]; then
      echo "$dir/scripts/moos_scoped_teardown.sh"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

#------------------------------------------------------------
#  Part 2: Set global variable default values
#------------------------------------------------------------
ME=`basename "$0"`
CMD_ARGS=""
TIME_WARP=10
MAX_TIME=60
NOGUI="--nogui"
VERBOSE=""
JUST_MAKE=""
MMOD=""
FORWARD_ARGS=()

#------------------------------------------------------------
#  Part 3: Check for and handle command-line arguments
#------------------------------------------------------------
for ARGI; do
  CMD_ARGS+=" ${ARGI}"
  if [ "${ARGI}" = "--help" -o "${ARGI}" = "-h" ]; then
    echo "$ME [OPTIONS] [time_warp]                         "
    echo "  --help, -h             Show this help message   "
    echo "  --verbose, -v          Verbose launch summary   "
    echo "  --just_make, -j        Only create targ files   "
    echo "  --nogui, -ng           Headless launch          "
    echo "  --gui                  Launch with pMarineViewer"
    echo "  --max_time=<secs>      Max time for xlaunch     "
    echo "  --mmod=<name>          Mission variation label  "
    echo "  --shore_mport=<port>   Shoreside MOOSDB port    "
    echo "  --veh_mport=<port>     Vehicle MOOSDB port      "
    echo "  --shore_pshare=<port>  Shoreside pShare port    "
    echo "  --veh_pshare=<port>    Vehicle pShare port      "
    exit 0
  elif [ "${ARGI//[^0-9]/}" = "$ARGI" -a "$TIME_WARP" = 10 ]; then
    TIME_WARP=$ARGI
  elif [ "${ARGI}" = "--verbose" -o "${ARGI}" = "-v" ]; then
    VERBOSE="--verbose"
  elif [ "${ARGI}" = "--just_make" -o "${ARGI}" = "-j" ]; then
    JUST_MAKE="--just_make"
  elif [ "${ARGI}" = "--nogui" -o "${ARGI}" = "-ng" ]; then
    NOGUI="--nogui"
  elif [ "${ARGI}" = "--gui" ]; then
    NOGUI=""
  elif [ "${ARGI:0:11}" = "--max_time=" ]; then
    MAX_TIME="${ARGI#--max_time=*}"
  elif [ "${ARGI:0:7}" = "--mmod=" ]; then
    MMOD="${ARGI#--mmod=*}"
  elif [ "${ARGI:0:14}" = "--shore_mport=" ]; then
    FORWARD_ARGS+=("${ARGI}")
  elif [ "${ARGI:0:12}" = "--veh_mport=" ]; then
    FORWARD_ARGS+=("${ARGI}")
  elif [ "${ARGI:0:15}" = "--shore_pshare=" ]; then
    FORWARD_ARGS+=("${ARGI}")
  elif [ "${ARGI:0:13}" = "--veh_pshare=" ]; then
    FORWARD_ARGS+=("${ARGI}")
  else
    echo "$ME: Bad Arg:[$ARGI]. Exit Code 1."
    exit 1
  fi
done

#------------------------------------------------------------
#  Part 4: Run the mission through shared xlaunch.sh
#------------------------------------------------------------
: > results.txt
xlaunch.sh --max_time="$MAX_TIME" $NOGUI $JUST_MAKE $VERBOSE \
  ${MMOD:+--mmod=$MMOD} "${FORWARD_ARGS[@]}" "$TIME_WARP"
status=$?

if [ "${JUST_MAKE}" = "" ]; then
  for try in 1 2 3; do
    grep -q 'grade=' results.txt 2>/dev/null && break
    sleep 1
  done
  if ! grep -q 'grade=' results.txt 2>/dev/null; then
    echo "$ME: results.txt does not contain a grade= result"
    status=1
  fi

  TEARDOWN_HELPER="$(find_teardown_helper)"
  if [ "$TEARDOWN_HELPER" = "" ]; then
    echo "$ME: Missing scoped teardown helper: scripts/moos_scoped_teardown.sh"
    status=1
  else
    "$TEARDOWN_HELPER" "$PWD" || status=1
  fi
fi

exit "$status"
