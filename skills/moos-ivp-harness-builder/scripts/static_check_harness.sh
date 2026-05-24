#!/usr/bin/env bash
set -u

harness_dir="${1:-.}"
fail=0
script_dir="$(cd "$(dirname "$0")" && pwd)"
eval_checker="$script_dir/../../moos-ivp-eval-mission-builder/scripts/static_check_eval_mission.sh"

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

need_file() {
  local rel="$1"
  if [ ! -f "$harness_dir/$rel" ]; then
    echo "FAIL missing $rel"
    fail=1
  fi
}

need_grep() {
  local pattern="$1"
  local rel="$2"
  local label="$3"
  if [ ! -f "$harness_dir/$rel" ] || ! search_file "$pattern" "$harness_dir/$rel"; then
    echo "FAIL missing $label in $rel"
    fail=1
  fi
}

need_file "README.md"
need_file "zlaunch.sh"

for stem_rel in stem stem_mission mission; do
  if [ -d "$harness_dir/$stem_rel" ] && [ -x "$eval_checker" ]; then
    if ! "$eval_checker" "$harness_dir/$stem_rel"; then
      echo "FAIL stem mission $stem_rel does not pass eval mission structural checks"
      fail=1
    fi
  fi
done

need_grep 'Cases|Current Matrix' "README.md" "case matrix documentation"
need_grep '--case' "zlaunch.sh" "--case support"
if [ -f "$harness_dir/zlaunch.sh" ] && ! search_file '--jobs' "$harness_dir/zlaunch.sh"; then
  echo "WARN zlaunch.sh omits --jobs; serial-only harnesses may omit it, but generated regression harnesses should usually implement wave execution"
fi
if [ -f "$harness_dir/zlaunch.sh" ] &&
   search_file '--jobs' "$harness_dir/zlaunch.sh" &&
   ! search_file 'run_wave|WAVE_|[[:space:]]&([[:space:]]|$)|(^|[^[:alnum:]_])wait([^[:alnum:]_]|$)|background' "$harness_dir/zlaunch.sh"; then
  echo "FAIL zlaunch.sh accepts --jobs but does not show obvious wave/background execution; omit --jobs or implement real grouped execution"
  fail=1
fi
need_grep '--port_base' "zlaunch.sh" "--port_base support"
need_grep '--max_time' "zlaunch.sh" "--max_time support"
need_grep 'get_case_config|case[[:space:]].*in' "zlaunch.sh" "explicit case mapping"
need_grep 'grade=' "zlaunch.sh" "mission grade parsing"
need_grep 'case=' "zlaunch.sh" "case-tagged result rows"
need_grep 'reason=' "zlaunch.sh" "runner-failure reason rows"
if [ -f "$harness_dir/zlaunch.sh" ] && search_file 'case_result[[:space:]]*=[[:space:]]*(pass|fail)([^[:alnum:]_]|$)' "$harness_dir/zlaunch.sh"; then
  echo "FAIL case_result uses pass/fail; publish grade=pass|fail directly instead of wrapping it in case_result"
  fail=1
fi
if [ -f "$harness_dir/zlaunch.sh" ] && search_file 'case_result=' "$harness_dir/zlaunch.sh"; then
  echo "WARN zlaunch.sh uses legacy case_result rows; ordinary harnesses should publish case=<case> plus the mission grade row"
fi
if [ -f "$harness_dir/zlaunch.sh" ] && search_file 'expected[[:space:]]*=|EXPECTED=' "$harness_dir/zlaunch.sh"; then
  echo "WARN zlaunch.sh appears to compare expected/actual grades; new harnesses should make pMissionEval own expected-negative semantics"
fi
if [ -f "$harness_dir/zlaunch.sh" ] && search_file '(^|[^[:alnum:]_])(mapfile|readarray)([^[:alnum:]_]|$)|declare[[:space:]]+-A' "$harness_dir/zlaunch.sh"; then
  echo "FAIL zlaunch.sh uses bash features unavailable in macOS system bash; avoid mapfile/readarray/associative arrays in portable harnesses"
  fail=1
fi
if [ -f "$harness_dir/zlaunch.sh" ] && ! search_file 'no cases selected|no selected cases|selected_count|case_count|CASE_COUNT|result_count|RESULT_COUNT|rows_written|result_rows' "$harness_dir/zlaunch.sh"; then
  echo "WARN zlaunch.sh does not show an obvious zero-selected/zero-result guard; selected runs should exit nonzero if no case rows are produced"
fi
need_grep 'mktemp|cp -R' "zlaunch.sh" "temp mission copy pattern"
need_grep 'PORT_STRIDE|case_base|port_base' "zlaunch.sh" "port block isolation"
need_grep 'shore_mport|veh_mport|shore_pshare|veh_pshare' "zlaunch.sh" "stem port forwarding"
need_grep 'harness_teardown_stop_root|scripts/harness_teardown\.sh|TEARDOWN_HELPER|recorded.*PID|child.*PID' "zlaunch.sh" "root-scoped teardown helper or recorded PID cleanup"
if [ -f "$harness_dir/zlaunch.sh" ] && ! search_file 'PSHARE_OFFSET|PORT_STRIDE[[:space:]]*/[[:space:]]*2' "$harness_dir/zlaunch.sh"; then
  echo "WARN zlaunch.sh does not show the midpoint pShare offset pattern; check custom port capacity manually"
fi
if [ -f "$harness_dir/zlaunch.sh" ] && search_file '^[[:space:]]*PORT_BASE=[23][0-9][0-9][0-9][0-9]([^0-9]|$)' "$harness_dir/zlaunch.sh"; then
  echo "WARN zlaunch.sh defaults to a high PORT_BASE; ordinary generated harnesses should default to 9000 and use high bases as explicit overrides"
fi
need_grep 'keep_workdirs|KEEP_WORKDIRS' "zlaunch.sh" "preserved workdir support"

if [ -f "$harness_dir/zlaunch.sh" ] && search_file 'nspatch' "$harness_dir/zlaunch.sh"; then
  need_grep '--stem=' "zlaunch.sh" "nspatch stem argument"
  need_grep '--targ=' "zlaunch.sh" "nspatch target sidecar"
fi

if [ -f "$harness_dir/zlaunch.sh" ]; then
  if command -v rg >/dev/null 2>&1; then
    rg -n '(^|[^[:alnum:]_])(ktm|pkill|killall)([^[:alnum:]_]|$)' "$harness_dir/zlaunch.sh" >/dev/null && bad_cleanup=yes || bad_cleanup=no
  else
    grep -En '(^|[^[:alnum:]_])(ktm|pkill|killall)([^[:alnum:]_]|$)' "$harness_dir/zlaunch.sh" >/dev/null && bad_cleanup=yes || bad_cleanup=no
  fi
  if [ "$bad_cleanup" = "yes" ]; then
    echo "FAIL zlaunch.sh uses global cleanup; prefer scoped teardown"
    fail=1
  fi
  if search_file 'lsof[[:space:]].*\+D.*\|.*(xargs[[:space:]]+)?kill' "$harness_dir/zlaunch.sh" ||
     { search_file 'lsof[[:space:]].*\+D' "$harness_dir/zlaunch.sh" &&
       search_file 'xargs[[:space:]]+kill' "$harness_dir/zlaunch.sh"; }; then
    echo "FAIL zlaunch.sh uses unsafe lsof +D kill cleanup; filter recorded MOOS app PIDs or known MOOS process names"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS harness structural checks"
fi

exit "$fail"
