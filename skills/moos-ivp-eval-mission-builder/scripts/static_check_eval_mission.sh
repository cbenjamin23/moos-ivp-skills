#!/usr/bin/env bash
set -u

mission_dir="${1:-.}"
fail=0

search_file() {
  local pattern="$1"
  local file="$2"
  local content_cmd="sed /^[[:space:]]*\\/\\//d"
  case "$file" in
    *.sh) content_cmd="sed s/[[:space:]]*#.*$//" ;;
  esac
  if command -v rg >/dev/null 2>&1; then
    $content_cmd "$file" | rg -q -- "$pattern"
  else
    $content_cmd "$file" | grep -Eq -- "$pattern"
  fi
}

meta_files() {
  local meta="$mission_dir/meta_shoreside.moos"
  echo "$meta"
  if [ -f "$meta" ]; then
    awk '/^[[:space:]]*#include[[:space:]]+/ {
      for (i = 2; i <= NF; i++) {
        if ($i ~ /^[^<].*\.moos$/) {
          print $i
          break
        }
      }
    }' "$meta" | while read -r rel; do
      [ -f "$mission_dir/$rel" ] && echo "$mission_dir/$rel"
    done
  fi
}

need_file() {
  local rel="$1"
  if [ ! -f "$mission_dir/$rel" ]; then
    echo "FAIL missing $rel"
    fail=1
  fi
}

need_grep() {
  local pattern="$1"
  local rel="$2"
  local label="$3"
  if [ ! -f "$mission_dir/$rel" ] || ! search_file "$pattern" "$mission_dir/$rel"; then
    echo "FAIL missing $label in $rel"
    fail=1
  fi
}

need_meta_grep() {
  local pattern="$1"
  local label="$2"
  local found=0
  for file in `meta_files`; do
    if [ -f "$file" ] && search_file "$pattern" "$file"; then
      found=1
    fi
  done
  if [ "$found" -eq 0 ]; then
    echo "FAIL missing $label in meta_shoreside.moos or local includes"
    fail=1
  fi
}

meta_has() {
  local pattern="$1"
  for file in `meta_files`; do
    if [ -f "$file" ] && search_file "$pattern" "$file"; then
      return 0
    fi
  done
  return 1
}

need_file "README.md"
need_file "launch.sh"
need_file "zlaunch.sh"
need_file "meta_shoreside.moos"

if ! meta_has 'ProcessConfig[[:space:]]*=[[:space:]]*pAutoPoke'; then
  if meta_has 'ProcessConfig[[:space:]]*=[[:space:]]*uTimerScript'; then
    echo "WARN no pAutoPoke config found; acceptable for unit-style evals if uTimerScript or the app under test owns initialization"
  else
    echo "FAIL missing pAutoPoke or uTimerScript initialization config in meta_shoreside.moos or local includes"
    fail=1
  fi
fi
need_meta_grep 'ProcessConfig[[:space:]]*=[[:space:]]*pMissionEval' "pMissionEval config"
need_meta_grep 'result_flag[[:space:]]*=[[:space:]]*MISSION_EVALUATED[[:space:]]*=[[:space:]]*true' "MISSION_EVALUATED result flag"
need_meta_grep 'report_file[[:space:]]*=[[:space:]]*results.txt' "results.txt report file"
need_meta_grep 'report_column[[:space:]]*=.*grade=' "grade report column"
need_meta_grep 'lead_condition[[:space:]]*=' "lead condition"
need_meta_grep 'pass_condition[[:space:]]*=' "pass condition"
if meta_has 'lead_condition[[:space:]]*=.*[[:space:]][Oo][Rr][[:space:]]' ||
   meta_has 'lead_condition[[:space:]]*=.*\|\|'; then
  echo "FAIL compound OR lead_condition detected; publish a helper boolean such as EVAL_WINDOW_DONE and use that as the pMissionEval lead"
  fail=1
fi
if meta_has 'report_column[[:space:]]*=.*mhash='; then
  need_meta_grep 'pMissionHash' "pMissionHash for mhash column"
fi
need_grep 'xlaunch.sh' "zlaunch.sh" "xlaunch call"
need_grep '--max_time' "zlaunch.sh" "max_time support"
need_grep 'results.txt' "zlaunch.sh" "results truncation or handling"
need_grep 'grade=' "zlaunch.sh" "missing grade detection"

if [ -f "$mission_dir/zlaunch.sh" ]; then
  if search_file 'grade=.*>[[:space:]]*results[.]txt|printf[[:space:]].*grade=.*results[.]txt|grade_hint' "$mission_dir/zlaunch.sh"; then
    echo "FAIL zlaunch.sh appears to synthesize grade=; pMissionEval should write results.txt"
    fail=1
  fi
  if command -v rg >/dev/null 2>&1; then
    rg -n '(^|[^[:alnum:]_])(ktm|pkill|killall)([^[:alnum:]_]|$)' "$mission_dir/zlaunch.sh" >/dev/null && bad_cleanup=yes || bad_cleanup=no
  else
    grep -En '(^|[^[:alnum:]_])(ktm|pkill|killall)([^[:alnum:]_]|$)' "$mission_dir/zlaunch.sh" >/dev/null && bad_cleanup=yes || bad_cleanup=no
  fi
  if [ "$bad_cleanup" = "yes" ]; then
    echo "FAIL zlaunch.sh uses global cleanup; prefer scoped teardown"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS eval mission structural checks"
fi

exit "$fail"
