#!/bin/bash
#------------------------------------------------------------
#   Script: launch.sh
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
LOG_CLEAN="no"
XLAUNCHED="no"
NOGUI="no"

VNAME="abe"
COLOR="yellow"
START_POS="x=0,y=0,heading=0"
VDEST_POS="25,-12"
STOCK_SPD="1.4"
MAX_SPD="2.0"
MMOD="single_point_arrival"

SHORE_MPORT="9000"
VEH_MPORT="9001"
SHORE_PSHARE="9200"
VEH_PSHARE="9201"

#------------------------------------------------------------
#  Part 3: Check for and handle command-line arguments
#------------------------------------------------------------
for ARGI; do
  CMD_ARGS+=" ${ARGI}"
  if [ "${ARGI}" = "--help" -o "${ARGI}" = "-h" ]; then
    echo "$ME [OPTIONS] [time_warp]                         "
    echo "                                                  "
    echo "Options:                                          "
    echo "  --help, -h             Show this help message   "
    echo "  --verbose, -v          Verbose launch summary   "
    echo "  --just_make, -j        Only create targ files   "
    echo "  --log_clean, -lc       Run clean.sh before launch"
    echo "  --xlaunched, -x        Launched by automation   "
    echo "  --nogui, -ng           No pMarineViewer         "
    echo "  --gui                  Explicit pMarineViewer   "
    echo "                                                  "
    echo "  --vname=<abe>          Vehicle name             "
    echo "  --color=<yellow>       Vehicle color            "
    echo "  --start_pos=<x,y,hdg>  Vehicle start position   "
    echo "  --vdest=<x,y>          Evaluated waypoint        "
    echo "  --stock_spd=<m/s>      Behavior speed           "
    echo "  --max_spd=<m/s>        Helm/sim max speed        "
    echo "  --mmod=<name>          Mission variation label   "
    echo "                                                  "
    echo "  --shore_mport=<9000>   Shoreside MOOSDB port    "
    echo "  --veh_mport=<9001>     Vehicle MOOSDB port      "
    echo "  --shore_pshare=<9200>  Shoreside pShare port    "
    echo "  --veh_pshare=<9201>    Vehicle pShare port      "
    exit 0
  elif [ "${ARGI//[^0-9]/}" = "$ARGI" -a "$TIME_WARP" = 1 ]; then
    TIME_WARP=$ARGI
  elif [ "${ARGI}" = "--verbose" -o "${ARGI}" = "-v" ]; then
    VERBOSE="yes"
  elif [ "${ARGI}" = "--just_make" -o "${ARGI}" = "-j" ]; then
    JUST_MAKE="yes"
  elif [ "${ARGI}" = "--log_clean" -o "${ARGI}" = "-lc" ]; then
    LOG_CLEAN="yes"
  elif [ "${ARGI}" = "--xlaunched" -o "${ARGI}" = "-x" ]; then
    XLAUNCHED="yes"
  elif [ "${ARGI}" = "--nogui" -o "${ARGI}" = "-ng" ]; then
    NOGUI="yes"
  elif [ "${ARGI}" = "--gui" ]; then
    NOGUI="no"
  elif [ "${ARGI:0:8}" = "--vname=" ]; then
    VNAME="${ARGI#--vname=*}"
  elif [ "${ARGI:0:8}" = "--color=" ]; then
    COLOR="${ARGI#--color=*}"
  elif [ "${ARGI:0:12}" = "--start_pos=" ]; then
    START_POS="${ARGI#--start_pos=*}"
  elif [ "${ARGI:0:8}" = "--vdest=" ]; then
    VDEST_POS="${ARGI#--vdest=*}"
  elif [ "${ARGI:0:12}" = "--stock_spd=" ]; then
    STOCK_SPD="${ARGI#--stock_spd=*}"
  elif [ "${ARGI:0:10}" = "--max_spd=" ]; then
    MAX_SPD="${ARGI#--max_spd=*}"
  elif [ "${ARGI:0:7}" = "--mmod=" ]; then
    MMOD="${ARGI#--mmod=*}"
  elif [ "${ARGI:0:14}" = "--shore_mport=" ]; then
    SHORE_MPORT="${ARGI#--shore_mport=*}"
  elif [ "${ARGI:0:12}" = "--veh_mport=" ]; then
    VEH_MPORT="${ARGI#--veh_mport=*}"
  elif [ "${ARGI:0:15}" = "--shore_pshare=" ]; then
    SHORE_PSHARE="${ARGI#--shore_pshare=*}"
  elif [ "${ARGI:0:13}" = "--veh_pshare=" ]; then
    VEH_PSHARE="${ARGI#--veh_pshare=*}"
  else
    echo "$ME: Bad Arg:[$ARGI]. Exit Code 1."
    exit 1
  fi
done

#------------------------------------------------------------
#  Part 4: If verbose, show vars and confirm before launching
#------------------------------------------------------------
if [ "${VERBOSE}" = "yes" ]; then
  echo "============================================"
  echo "  $ME SUMMARY"
  echo "============================================"
  echo "CMD_ARGS =       [${CMD_ARGS}]"
  echo "TIME_WARP =      [${TIME_WARP}]"
  echo "JUST_MAKE =      [${JUST_MAKE}]"
  echo "LOG_CLEAN =      [${LOG_CLEAN}]"
  echo "XLAUNCHED =      [${XLAUNCHED}]"
  echo "NOGUI =          [${NOGUI}]"
  echo "VNAME =          [${VNAME}]"
  echo "COLOR =          [${COLOR}]"
  echo "START_POS =      [${START_POS}]"
  echo "VDEST_POS =      [${VDEST_POS}]"
  echo "STOCK_SPD =      [${STOCK_SPD}]"
  echo "MAX_SPD =        [${MAX_SPD}]"
  echo "MMOD =           [${MMOD}]"
  echo "SHORE_MPORT =    [${SHORE_MPORT}]"
  echo "VEH_MPORT =      [${VEH_MPORT}]"
  echo "SHORE_PSHARE =   [${SHORE_PSHARE}]"
  echo "VEH_PSHARE =     [${VEH_PSHARE}]"
  if [ "${XLAUNCHED}" != "yes" ]; then
    echo -n "Hit any key to continue launch "
    read ANSWER
  fi
fi

#------------------------------------------------------------
#  Part 5: Optionally clean old generated files
#------------------------------------------------------------
if [ "$LOG_CLEAN" = "yes" -a -f "clean.sh" ]; then
  ./clean.sh
fi

#------------------------------------------------------------
#  Part 6: Launch the vehicle community
#------------------------------------------------------------
VARGS=(--auto "$TIME_WARP" --mport="$VEH_MPORT" --pshare="$VEH_PSHARE")
VARGS+=(--shore_pshare="$SHORE_PSHARE" --vname="$VNAME" --color="$COLOR")
VARGS+=(--start_pos="$START_POS" --vdest="$VDEST_POS")
VARGS+=(--stock_spd="$STOCK_SPD" --max_spd="$MAX_SPD")
[ "$JUST_MAKE" = "yes" ] && VARGS+=(--just_make)
[ "$VERBOSE" = "yes" ] && VARGS+=(--verbose)

vecho "Launching vehicle with args: ${VARGS[*]}"
./launch_vehicle.sh "${VARGS[@]}"

#------------------------------------------------------------
#  Part 7: Launch the shoreside community
#------------------------------------------------------------
SARGS=(--auto "$TIME_WARP" --mport="$SHORE_MPORT" --pshare="$SHORE_PSHARE")
SARGS+=(--vnames="$VNAME" --mmod="$MMOD")
[ "$JUST_MAKE" = "yes" ] && SARGS+=(--just_make)
[ "$VERBOSE" = "yes" ] && SARGS+=(--verbose)
[ "$NOGUI" = "yes" ] && SARGS+=(--nogui)

vecho "Launching shoreside with args: ${SARGS[*]}"
./launch_shoreside.sh "${SARGS[@]}"

if [ "${JUST_MAKE}" = "yes" ]; then
  echo "$ME: Targ files made; exiting without launch."
  exit 0
fi

#------------------------------------------------------------
#  Part 8: Unless automation launched, open one uMAC session
#------------------------------------------------------------
if [ "${XLAUNCHED}" != "yes" ]; then
  uMAC --paused targ_shoreside.moos
  trap "" SIGINT
  echo; echo "$ME: Halting all apps"
  kill -- -$$
fi

exit 0
