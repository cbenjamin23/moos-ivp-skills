#!/usr/bin/env bash
set -u

failures=0
root="${1:-${MOOS_IVP_ROOT:-}}"

ok() {
  printf 'ok - %s\n' "$1"
}

fail() {
  printf 'fail - %s\n' "$1"
  failures=$((failures + 1))
}

check_file() {
  [ -f "$2" ] && ok "$1 exists" || fail "$1 missing at $2"
}

check_dir() {
  [ -d "$2" ] && ok "$1 exists" || fail "$1 missing at $2"
}

check_exec() {
  [ -x "$2" ] && ok "$1 is executable" || fail "$1 missing or not executable at $2"
}

if [ -z "$root" ]; then
  for candidate in "$HOME/moos-ivp" "$HOME/src/moos-ivp" "$HOME/repos/moos-ivp" "$HOME/projects/moos-ivp"; do
    if [ -d "$candidate" ]; then
      root="$candidate"
      break
    fi
  done
fi

if [ -z "$root" ]; then
  fail "no checkout path supplied, MOOS_IVP_ROOT is unset, and no common checkout path exists"
  printf 'validation failed (%d issue)\n' "$failures"
  exit 1
fi

if ! root="$(cd "$root" 2>/dev/null && pwd -P)"; then
  fail "checkout path does not exist or is not accessible: ${1:-${MOOS_IVP_ROOT:-}}"
  printf 'validation failed (%d issue)\n' "$failures"
  exit 1
fi

ok "checking $root"

check_dir "ivp/src" "$root/ivp/src"
check_file "README.md" "$root/README.md"
check_file "README-GNULINUX.txt" "$root/README-GNULINUX.txt"
check_file "README-OS-X.txt" "$root/README-OS-X.txt"
check_file "README-WINDOWS.txt" "$root/README-WINDOWS.txt"
check_exec "build-moos.sh" "$root/build-moos.sh"
check_exec "build-ivp.sh" "$root/build-ivp.sh"
check_exec "pAntler" "$root/bin/pAntler"
check_exec "GenMOOSApp_AppCasting" "$root/scripts/GenMOOSApp_AppCasting"
check_exec "GenBehavior" "$root/scripts/GenBehavior"
check_file "env.sh" "$root/env.sh"

env_file="$root/env.sh"
if [ -f "$env_file" ]; then
  bash -c '
    set -u
    env_file="$1"
    root="$2"
    . "$env_file" >/dev/null 2>&1 || exit 20
    [ "${MOOS_IVP_ROOT:-}" = "$root" ] || exit 21
    case ":$PATH:" in *":$root/bin:"*) ;; *) exit 22 ;; esac
    case ":$PATH:" in *":$root/scripts:"*) ;; *) exit 23 ;; esac
    command -v pAntler >/dev/null 2>&1 || exit 24
    command -v GenMOOSApp_AppCasting >/dev/null 2>&1 || exit 25
    command -v GenBehavior >/dev/null 2>&1 || exit 26
  ' validate-env "$env_file" "$root"
  case "$?" in
    0) ok "env.sh sets MOOS_IVP_ROOT and exposes required tools on PATH" ;;
    20) fail "env.sh could not be sourced" ;;
    21) fail "env.sh does not set MOOS_IVP_ROOT to $root" ;;
    22) fail "env.sh does not add $root/bin to PATH" ;;
    23) fail "env.sh does not add $root/scripts to PATH" ;;
    24) fail "pAntler is not found after sourcing env.sh" ;;
    25) fail "GenMOOSApp_AppCasting is not found after sourcing env.sh" ;;
    26) fail "GenBehavior is not found after sourcing env.sh" ;;
    *) fail "env.sh validation failed unexpectedly" ;;
  esac
fi

if [ "$failures" -eq 0 ]; then
  printf 'validation passed\n'
  exit 0
fi

printf 'validation failed (%d issues)\n' "$failures"
exit 1
