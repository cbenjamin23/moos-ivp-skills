#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
checker="$repo_root/skills/moos-app-builder/scripts/check_portable_paths.sh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/moos_portable_paths.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/build" "$fixture/build-alt" "$fixture/logs" "$fixture/src"
printf '%s\n' 'set(MOOS_IVP_ROOT "$ENV{MOOS_IVP_ROOT}" CACHE PATH "MOOS-IvP checkout")' > "$fixture/CMakeLists.txt"
printf '%s\n' 'MOOS_IVP_ROOT:PATH=/opt/moos-ivp' > "$fixture/build/CMakeCache.txt"
printf '%s\n' '/home/builder/src/moos-ivp' > "$fixture/build-alt/configure.txt"
printf '%s\n' '/Users/operator/dev/moos-ivp' > "$fixture/logs/runtime.log"

safe_output="$($checker "$fixture")"
grep -Fq 'PASS no fixed MOOS-IvP checkout paths found' <<<"$safe_output"

printf '%s\n' 'set(MOOS_IVP_ROOT "/opt/moos-ivp" CACHE PATH "MOOS-IvP checkout")' > "$fixture/src/fixed.cmake"
printf '%s\n' '/Users/operator/dev/moos-ivp/bin/pAntler' > "$fixture/src/fixed-macos.sh"
printf '%s\n' '/home/operator/dev/moos-ivp/bin/pAntler' > "$fixture/src/fixed-linux.sh"
warning_output="$($checker "$fixture")"
grep -Fq 'warning: src/fixed.cmake contains a fixed MOOS-IvP checkout path' <<<"$warning_output"
grep -Fq 'warning: src/fixed-macos.sh contains a fixed MOOS-IvP checkout path' <<<"$warning_output"
grep -Fq 'warning: src/fixed-linux.sh contains a fixed MOOS-IvP checkout path' <<<"$warning_output"
if grep -Eq 'warning: (build|build-alt|logs)/' <<<"$warning_output"; then
  echo "unexpected warning for an ignored build/log path" >&2
  exit 1
fi

echo "PASS portable-path checker"
