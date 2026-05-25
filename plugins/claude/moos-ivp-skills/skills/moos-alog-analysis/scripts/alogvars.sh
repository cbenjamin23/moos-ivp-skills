#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  alogvars.sh <alog_path> [PREFIX ...] [--names-only]

Examples:
  alogvars.sh mission.alog
  alogvars.sh mission.alog NAV_ WPT_
  alogvars.sh mission.alog --names-only NAV_ MODE

Notes:
  - Wraps: alogscan <alog_path> --sort=vars --nocolors
  - Additional positional arguments are treated as variable-name prefixes.
  - Use --names-only for the narrowest discovery output.
EOF
}

if [ "$#" -lt 1 ]; then
  usage >&2
  exit 1
fi

alog_path=""
names_only=0
prefixes=()

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --names-only)
      names_only=1
      ;;
    *)
      if [ -z "$alog_path" ]; then
        alog_path="$arg"
      else
        prefixes+=("$arg")
      fi
      ;;
  esac
done

if [ ! -f "$alog_path" ]; then
  echo "alogvars.sh: file not found: $alog_path" >&2
  exit 1
fi

raw_output="$(alogscan "$alog_path" --sort=vars --nocolors 2>&1)"

prefix_blob=""
if [ "${#prefixes[@]}" -gt 0 ]; then
  prefix_blob="$(IFS=,; echo "${prefixes[*]}")"
fi

if [ "$names_only" -eq 1 ]; then
  printf '%s\n' "$raw_output" | awk -v prefixes="$prefix_blob" '
    BEGIN {
      split(prefixes, p, ",")
      want_prefix = (prefixes != "")
      in_rows = 0
    }
    /^Variable Name[[:space:]]+Lines/ { in_rows = 1; next }
    /^-+$/ { if (in_rows) exit }
    !in_rows { next }
    /^-------------/ { next }
    NF {
      var = $1
      if (!want_prefix || has_prefix(var, p)) {
        print var
      }
    }
    function has_prefix(var, arr,   i) {
      for (i in arr) {
        if (arr[i] != "" && index(var, arr[i]) == 1) {
          return 1
        }
      }
      return 0
    }
  '
  exit 0
fi

printf '%s\n' "$raw_output" | awk -v prefixes="$prefix_blob" '
  BEGIN {
    split(prefixes, p, ",")
    want_prefix = (prefixes != "")
    row_count = 0
    printed_header = 0
    in_rows = 0
  }
  /^Variable Name[[:space:]]+Lines/ {
    print
    printed_header = 1
    in_rows = 1
    next
  }
  /^-+$/ {
    if (printed_header) {
      print
    }
    exit
  }
  /^-------------[[:space:]]+/ {
    if (printed_header) {
      print
    }
    next
  }
  !in_rows { next }
  NF {
    var = $1
    if (!want_prefix || has_prefix(var, p)) {
      print
      row_count++
    }
  }
  END {
    if (row_count > 0 || printed_header) {
      printf("Matched variables: %d\n", row_count)
    }
  }
  function has_prefix(var, arr,   i) {
    for (i in arr) {
      if (arr[i] != "" && index(var, arr[i]) == 1) {
        return 1
      }
    }
    return 0
  }
'
