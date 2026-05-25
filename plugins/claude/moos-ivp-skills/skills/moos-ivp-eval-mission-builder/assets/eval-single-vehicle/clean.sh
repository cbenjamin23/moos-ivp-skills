#!/bin/bash
#--------------------------------------------------------------
#   Script: clean.sh
#   Author: MOOS-IvP Skills
#--------------------------------------------------------------
#  Part 1: Declare global var defaults
#--------------------------------------------------------------
VERBOSE=""

#--------------------------------------------------------------
#  Part 2: Check for and handle command-line arguments
#--------------------------------------------------------------
for ARGI; do
  if [ "${ARGI}" = "--help" -o "${ARGI}" = "-h" ]; then
    echo "clean.sh [OPTIONS]"
    echo "  --verbose, -v"
    echo "  --help, -h"
    exit 0
  elif [ "${ARGI}" = "--verbose" -o "${ARGI}" = "-v" ]; then
    VERBOSE="-v"
  else
    echo "clean.sh: Bad Arg:[$ARGI]. Exit Code 1."
    exit 1
  fi
done

#--------------------------------------------------------------
#  Part 3: Remove generated files and logs
#--------------------------------------------------------------
if [ "${VERBOSE}" = "-v" ]; then
  echo "Cleaning: $PWD"
fi

rm -rf $VERBOSE MOOSLog_* XLOG_* LOG_*
rm -f  $VERBOSE *~ targ_* tmp_* *.moosx *.bhvx
rm -f  $VERBOSE .LastOpenedMOOSLogDirectory .mem_info*
