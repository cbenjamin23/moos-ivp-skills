#!/bin/bash
#------------------------------------------------------------
#   Script: launch.sh
#  Mission: baseline-two-vehicle
#   Author: Author Name
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

ALPHA_COLOR="yellow"
ALPHA_START_POS="x=0,y=0,heading=0"
ALPHA_VDEST_POS="80,-40"
ALPHA_SURVEY_POLY="0,0:80,0:80,-80:0,-80"

BRAVO_COLOR="red"
BRAVO_START_POS="x=0,y=-100,heading=0"
BRAVO_VDEST_POS="80,-140"
BRAVO_SURVEY_POLY="0,-100:80,-100:80,-180:0,-180"

STOCK_SPD="1.4"
MAX_SPD="2.0"

SHORE_MPORT="9000"
VEH_MPORT="9001"
ALPHA_MPORT="9001"
BRAVO_MPORT="9002"
SHORE_PSHARE="9200"
VEH_PSHARE="9201"
ALPHA_PSHARE="9201"
BRAVO_PSHARE="9202"

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
    echo "                                                  "
    echo "  --alpha_color=<yellow> Alpha vehicle color      "
    echo "  --bravo_color=<red>    Bravo vehicle color      "
    echo "  --alpha_start=<x,y,h>  Alpha start position     "
    echo "  --bravo_start=<x,y,h>  Bravo start position     "
    echo "  --alpha_vdest=<x,y>    Alpha return point       "
    echo "  --bravo_vdest=<x,y>    Bravo return point       "
    echo "  --stock_spd=<m/s>      Behavior speed           "
    echo "  --max_spd=<m/s>        Helm/sim max speed        "
    echo "                                                  "
    echo "  --shore_mport=<9000>   Shoreside MOOSDB port    "
    echo "  --veh_mport=<9001>     Alpha MOOSDB port alias  "
    echo "  --alpha_mport=<9001>   Alpha MOOSDB port        "
    echo "  --bravo_mport=<9002>   Bravo MOOSDB port        "
    echo "  --shore_pshare=<9200>  Shoreside pShare port    "
    echo "  --veh_pshare=<9201>    Alpha pShare port alias  "
    echo "  --alpha_pshare=<9201>  Alpha pShare port        "
    echo "  --bravo_pshare=<9202>  Bravo pShare port        "
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
  elif [ "${ARGI:0:14}" = "--alpha_color=" ]; then
    ALPHA_COLOR="${ARGI#--alpha_color=*}"
  elif [ "${ARGI:0:14}" = "--bravo_color=" ]; then
    BRAVO_COLOR="${ARGI#--bravo_color=*}"
  elif [ "${ARGI:0:14}" = "--alpha_start=" ]; then
    ALPHA_START_POS="${ARGI#--alpha_start=*}"
  elif [ "${ARGI:0:14}" = "--bravo_start=" ]; then
    BRAVO_START_POS="${ARGI#--bravo_start=*}"
  elif [ "${ARGI:0:14}" = "--alpha_vdest=" ]; then
    ALPHA_VDEST_POS="${ARGI#--alpha_vdest=*}"
  elif [ "${ARGI:0:14}" = "--bravo_vdest=" ]; then
    BRAVO_VDEST_POS="${ARGI#--bravo_vdest=*}"
  elif [ "${ARGI:0:12}" = "--stock_spd=" ]; then
    STOCK_SPD="${ARGI#--stock_spd=*}"
  elif [ "${ARGI:0:10}" = "--max_spd=" ]; then
    MAX_SPD="${ARGI#--max_spd=*}"
  elif [ "${ARGI:0:14}" = "--shore_mport=" ]; then
    SHORE_MPORT="${ARGI#--shore_mport=*}"
  elif [ "${ARGI:0:12}" = "--veh_mport=" ]; then
    VEH_MPORT="${ARGI#--veh_mport=*}"
    ALPHA_MPORT="$VEH_MPORT"
  elif [ "${ARGI:0:14}" = "--alpha_mport=" ]; then
    ALPHA_MPORT="${ARGI#--alpha_mport=*}"
    VEH_MPORT="$ALPHA_MPORT"
  elif [ "${ARGI:0:14}" = "--bravo_mport=" ]; then
    BRAVO_MPORT="${ARGI#--bravo_mport=*}"
  elif [ "${ARGI:0:15}" = "--shore_pshare=" ]; then
    SHORE_PSHARE="${ARGI#--shore_pshare=*}"
  elif [ "${ARGI:0:13}" = "--veh_pshare=" ]; then
    VEH_PSHARE="${ARGI#--veh_pshare=*}"
    ALPHA_PSHARE="$VEH_PSHARE"
  elif [ "${ARGI:0:15}" = "--alpha_pshare=" ]; then
    ALPHA_PSHARE="${ARGI#--alpha_pshare=*}"
    VEH_PSHARE="$ALPHA_PSHARE"
  elif [ "${ARGI:0:15}" = "--bravo_pshare=" ]; then
    BRAVO_PSHARE="${ARGI#--bravo_pshare=*}"
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
  echo "ALPHA_COLOR =    [${ALPHA_COLOR}]"
  echo "ALPHA_START =    [${ALPHA_START_POS}]"
  echo "ALPHA_VDEST =    [${ALPHA_VDEST_POS}]"
  echo "BRAVO_COLOR =    [${BRAVO_COLOR}]"
  echo "BRAVO_START =    [${BRAVO_START_POS}]"
  echo "BRAVO_VDEST =    [${BRAVO_VDEST_POS}]"
  echo "STOCK_SPD =      [${STOCK_SPD}]"
  echo "MAX_SPD =        [${MAX_SPD}]"
  echo "SHORE_MPORT =    [${SHORE_MPORT}]"
  echo "ALPHA_MPORT =    [${ALPHA_MPORT}]"
  echo "BRAVO_MPORT =    [${BRAVO_MPORT}]"
  echo "SHORE_PSHARE =   [${SHORE_PSHARE}]"
  echo "ALPHA_PSHARE =   [${ALPHA_PSHARE}]"
  echo "BRAVO_PSHARE =   [${BRAVO_PSHARE}]"
  echo -n "Hit any key to continue launch "
  read ANSWER
fi

#------------------------------------------------------------
#  Part 5: Optionally clean old generated files
#------------------------------------------------------------
if [ "$LOG_CLEAN" = "yes" -a -f "clean.sh" ]; then
  ./clean.sh
fi

#------------------------------------------------------------
#  Part 6: Launch the vehicle communities
#------------------------------------------------------------
VEHICLE_NAMES=("alpha" "bravo")
VEHICLE_COLORS=("$ALPHA_COLOR" "$BRAVO_COLOR")
VEHICLE_STARTS=("$ALPHA_START_POS" "$BRAVO_START_POS")
VEHICLE_DESTS=("$ALPHA_VDEST_POS" "$BRAVO_VDEST_POS")
VEHICLE_POLYS=("$ALPHA_SURVEY_POLY" "$BRAVO_SURVEY_POLY")
VEHICLE_MPORTS=("$ALPHA_MPORT" "$BRAVO_MPORT")
VEHICLE_PSHARES=("$ALPHA_PSHARE" "$BRAVO_PSHARE")
VNAMES=$(IFS=:; echo "${VEHICLE_NAMES[*]}")

for IX in "${!VEHICLE_NAMES[@]}"; do
  VARGS=(--auto "$TIME_WARP")
  VARGS+=(--mport="${VEHICLE_MPORTS[$IX]}" --pshare="${VEHICLE_PSHARES[$IX]}")
  VARGS+=(--shore_pshare="$SHORE_PSHARE")
  VARGS+=(--vname="${VEHICLE_NAMES[$IX]}" --color="${VEHICLE_COLORS[$IX]}")
  VARGS+=(--start_pos="${VEHICLE_STARTS[$IX]}" --vdest="${VEHICLE_DESTS[$IX]}")
  VARGS+=(--survey_poly="${VEHICLE_POLYS[$IX]}")
  VARGS+=(--stock_spd="$STOCK_SPD" --max_spd="$MAX_SPD")
  [ "$JUST_MAKE" = "yes" ] && VARGS+=(--just_make)
  [ "$VERBOSE" = "yes" ] && VARGS+=(--verbose)

  vecho "Launching ${VEHICLE_NAMES[$IX]} with args: ${VARGS[*]}"
  ./launch_vehicle.sh "${VARGS[@]}" || exit 1
done

#------------------------------------------------------------
#  Part 7: Launch the shoreside community
#------------------------------------------------------------
SARGS=(--auto "$TIME_WARP" --mport="$SHORE_MPORT" --pshare="$SHORE_PSHARE")
SARGS+=(--vnames="$VNAMES")
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
