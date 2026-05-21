#!/bin/bash
#------------------------------------------------------------
#   Script: launch_shoreside.sh
#  Mission: eval-single-vehicle
#   Author: MOOS-IvP Skills
#------------------------------------------------------------
#  Part 1: Set convenience functions for terminal output and
#          catching SIGINT (ctrl-c).
#------------------------------------------------------------
vecho() { if [ "$VERBOSE" = "yes" ]; then echo "$ME: $1"; fi; }
on_exit() { echo; echo "$ME: Halting all apps"; kill -- -$$; }
trap on_exit SIGINT

#------------------------------------------------------------
#  Part 2: Set global variable default values
#------------------------------------------------------------
ME=`basename "$0"`
CMD_ARGS=""
TIME_WARP=1
VERBOSE="no"
JUST_MAKE="no"
AUTO_LAUNCHED="no"
LAUNCH_GUI="yes"

IP_ADDR="localhost"
MOOS_PORT="9000"
PSHARE_PORT="9200"
VNAMES="abe"
MMOD="single_point_arrival"

#------------------------------------------------------------
#  Part 3: Check for and handle command-line arguments
#------------------------------------------------------------
for ARGI; do
  CMD_ARGS+=" ${ARGI}"
  if [ "${ARGI}" = "--help" -o "${ARGI}" = "-h" ]; then
    echo "$ME [OPTIONS] [time_warp]                         "
    echo "  --help, -h             Show this help message   "
    echo "  --just_make, -j        Only create targ files   "
    echo "  --verbose, -v          Verbose launch summary   "
    echo "  --auto, -a             Script launch, no uMAC   "
    echo "  --nogui, -ng           No pMarineViewer         "
    echo "  --gui                  Explicit pMarineViewer   "
    echo "  --ip=<localhost>       Shoreside IP address     "
    echo "  --mport=<9000>         Shoreside MOOSDB port    "
    echo "  --pshare=<9200>        Shoreside pShare port    "
    echo "  --vnames=<abe>         Colon-separated vehicles "
    echo "  --mmod=<name>          Mission variation label  "
    exit 0
  elif [ "${ARGI//[^0-9]/}" = "$ARGI" -a "$TIME_WARP" = 1 ]; then
    TIME_WARP=$ARGI
  elif [ "${ARGI}" = "--just_make" -o "${ARGI}" = "-j" ]; then
    JUST_MAKE="yes"
  elif [ "${ARGI}" = "--verbose" -o "${ARGI}" = "-v" ]; then
    VERBOSE="yes"
  elif [ "${ARGI}" = "--auto" -o "${ARGI}" = "-a" ]; then
    AUTO_LAUNCHED="yes"
  elif [ "${ARGI}" = "--nogui" -o "${ARGI}" = "-ng" ]; then
    LAUNCH_GUI="no"
  elif [ "${ARGI}" = "--gui" ]; then
    LAUNCH_GUI="yes"
  elif [ "${ARGI:0:5}" = "--ip=" ]; then
    IP_ADDR="${ARGI#--ip=*}"
  elif [ "${ARGI:0:8}" = "--mport=" ]; then
    MOOS_PORT="${ARGI#--mport=*}"
  elif [ "${ARGI:0:9}" = "--pshare=" ]; then
    PSHARE_PORT="${ARGI#--pshare=*}"
  elif [ "${ARGI:0:9}" = "--vnames=" ]; then
    VNAMES="${ARGI#--vnames=*}"
  elif [ "${ARGI:0:7}" = "--mmod=" ]; then
    MMOD="${ARGI#--mmod=*}"
  else
    echo "$ME: Bad Arg:[$ARGI]. Exit Code 1."
    exit 1
  fi
done

#------------------------------------------------------------
#  Part 4: Show verbose summary
#------------------------------------------------------------
if [ "${VERBOSE}" = "yes" ]; then
  echo "============================================"
  echo "  $ME SUMMARY"
  echo "============================================"
  echo "CMD_ARGS =      [${CMD_ARGS}]"
  echo "TIME_WARP =     [${TIME_WARP}]"
  echo "JUST_MAKE =     [${JUST_MAKE}]"
  echo "AUTO_LAUNCHED = [${AUTO_LAUNCHED}]"
  echo "LAUNCH_GUI =    [${LAUNCH_GUI}]"
  echo "IP_ADDR =       [${IP_ADDR}]"
  echo "MOOS_PORT =     [${MOOS_PORT}]"
  echo "PSHARE_PORT =   [${PSHARE_PORT}]"
  echo "VNAMES =        [${VNAMES}]"
  echo "MMOD =          [${MMOD}]"
fi

#------------------------------------------------------------
#  Part 5: Create the shoreside .moos file
#------------------------------------------------------------
NSFLAGS="--strict --force -x"
if [ "${AUTO_LAUNCHED}" = "no" ]; then
  NSFLAGS="--interactive --force -x"
fi

nsplug meta_shoreside.moos targ_shoreside.moos $NSFLAGS WARP=$TIME_WARP \
  IP_ADDR=$IP_ADDR MOOS_PORT=$MOOS_PORT PSHARE_PORT=$PSHARE_PORT \
  LAUNCH_GUI=$LAUNCH_GUI VNAMES=$VNAMES MMOD=$MMOD

if [ "${JUST_MAKE}" = "yes" ]; then
  echo "$ME: Targ files made; exiting without launch."
  exit 0
fi

#------------------------------------------------------------
#  Part 6: Launch the shoreside community
#------------------------------------------------------------
echo "Launching Shoreside MOOS Community. WARP=$TIME_WARP"
pAntler targ_shoreside.moos >& /dev/null &
echo "Done Launching Shoreside Community"

#------------------------------------------------------------
#  Part 7: If launched from another script, exit now
#------------------------------------------------------------
if [ "${AUTO_LAUNCHED}" = "yes" ]; then
  exit 0
fi

#------------------------------------------------------------
#  Part 8: Launch uMAC until the mission is quit
#------------------------------------------------------------
uMAC targ_shoreside.moos
trap "" SIGINT
kill -- -$$
