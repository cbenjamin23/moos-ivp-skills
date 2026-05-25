#!/bin/bash
#------------------------------------------------------------
#   Script: launch_vehicle.sh
#  Mission: baseline-single-vehicle
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
AUTO_LAUNCHED="no"

IP_ADDR="localhost"
MOOS_PORT="9001"
PSHARE_PORT="9201"
SHORE_IP="localhost"
SHORE_PSHARE="9200"

VNAME="abe"
COLOR="yellow"
START_POS="x=0,y=0,heading=0"
VDEST_POS="80,-40"
STOCK_SPD="1.4"
MAX_SPD="2.0"

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
    echo "  --ip=<localhost>       Vehicle IP address       "
    echo "  --mport=<9001>         Vehicle MOOSDB port      "
    echo "  --pshare=<9201>        Vehicle pShare port      "
    echo "  --shore=<localhost>    Shoreside host           "
    echo "  --shore_pshare=<9200>  Shoreside pShare port    "
    echo "  --vname=<abe>          Vehicle name             "
    echo "  --color=<yellow>       Vehicle color            "
    echo "  --start_pos=<x,y,hdg>  Vehicle start position   "
    echo "  --vdest=<x,y>          Survey/return point      "
    echo "  --stock_spd=<m/s>      Behavior speed           "
    echo "  --max_spd=<m/s>        Helm/sim max speed       "
    exit 0
  elif [ "${ARGI//[^0-9]/}" = "$ARGI" -a "$TIME_WARP" = 1 ]; then
    TIME_WARP=$ARGI
  elif [ "${ARGI}" = "--just_make" -o "${ARGI}" = "-j" ]; then
    JUST_MAKE="yes"
  elif [ "${ARGI}" = "--verbose" -o "${ARGI}" = "-v" ]; then
    VERBOSE="yes"
  elif [ "${ARGI}" = "--auto" -o "${ARGI}" = "-a" ]; then
    AUTO_LAUNCHED="yes"
  elif [ "${ARGI:0:5}" = "--ip=" ]; then
    IP_ADDR="${ARGI#--ip=*}"
  elif [ "${ARGI:0:8}" = "--mport=" ]; then
    MOOS_PORT="${ARGI#--mport=*}"
  elif [ "${ARGI:0:9}" = "--pshare=" ]; then
    PSHARE_PORT="${ARGI#--pshare=*}"
  elif [ "${ARGI:0:8}" = "--shore=" ]; then
    SHORE_IP="${ARGI#--shore=*}"
  elif [ "${ARGI:0:15}" = "--shore_pshare=" ]; then
    SHORE_PSHARE="${ARGI#--shore_pshare=*}"
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
  echo "  $ME SUMMARY for $VNAME"
  echo "============================================"
  echo "CMD_ARGS =      [${CMD_ARGS}]"
  echo "TIME_WARP =     [${TIME_WARP}]"
  echo "JUST_MAKE =     [${JUST_MAKE}]"
  echo "AUTO_LAUNCHED = [${AUTO_LAUNCHED}]"
  echo "IP_ADDR =       [${IP_ADDR}]"
  echo "MOOS_PORT =     [${MOOS_PORT}]"
  echo "PSHARE_PORT =   [${PSHARE_PORT}]"
  echo "SHORE_IP =      [${SHORE_IP}]"
  echo "SHORE_PSHARE =  [${SHORE_PSHARE}]"
  echo "START_POS =     [${START_POS}]"
  echo "VDEST_POS =     [${VDEST_POS}]"
fi

#------------------------------------------------------------
#  Part 5: Create the vehicle .moos and .bhv files
#------------------------------------------------------------
NSFLAGS="--strict --force -x"
if [ "${AUTO_LAUNCHED}" = "no" ]; then
  NSFLAGS="--interactive --force -x"
fi

nsplug meta_vehicle.moos targ_$VNAME.moos $NSFLAGS WARP=$TIME_WARP \
  IP_ADDR=$IP_ADDR MOOS_PORT=$MOOS_PORT PSHARE_PORT=$PSHARE_PORT \
  SHORE_IP=$SHORE_IP SHORE_PSHARE=$SHORE_PSHARE VNAME=$VNAME \
  COLOR=$COLOR START_POS=$START_POS MAX_SPD=$MAX_SPD

nsplug meta_vehicle.bhv targ_$VNAME.bhv $NSFLAGS \
  START_POS=$START_POS VNAME=$VNAME STOCK_SPD=$STOCK_SPD \
  VDEST_POS=$VDEST_POS

if [ "${JUST_MAKE}" = "yes" ]; then
  echo "$ME: Targ files made; exiting without launch."
  exit 0
fi

#------------------------------------------------------------
#  Part 6: Launch the vehicle community
#------------------------------------------------------------
echo "Launching $VNAME MOOS Community. WARP=$TIME_WARP"
pAntler targ_$VNAME.moos >& /dev/null &
echo "Done Launching $VNAME MOOS Community"

#------------------------------------------------------------
#  Part 7: If launched from another script, exit now
#------------------------------------------------------------
if [ "${AUTO_LAUNCHED}" = "yes" ]; then
  exit 0
fi

#------------------------------------------------------------
#  Part 8: Launch uMAC until the mission is quit
#------------------------------------------------------------
uMAC targ_$VNAME.moos
trap "" SIGINT
kill -- -$$

