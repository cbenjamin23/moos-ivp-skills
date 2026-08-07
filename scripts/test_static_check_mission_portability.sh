#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
checker="$repo_root/skills/moos-ivp-mission-builder/scripts/static_check_mission.sh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/moos_mission_portability.XXXXXX")"
trap 'rm -rf "$fixture"' EXIT

cp -R "$repo_root/skills/moos-ivp-mission-builder/assets/baseline-single-vehicle/." "$fixture/"

printf '%s\n' '#!/usr/bin/env bash' 'setsid pAntler mission.moos &' > "$fixture/platform_launch.sh"
printf '%s\n' '#!/usr/bin/env bash' 'for proc in /proc/[0-9]*; do :; done' > "$fixture/stop.sh"

warning_output="$(bash "$checker" "$fixture" || true)"
grep -Fq 'warning: launcher uses setsid without an availability check' <<<"$warning_output"
grep -Fq 'warning: stop.sh uses /proc without an obvious non-Linux fallback' <<<"$warning_output"

printf '%s\n' '#!/usr/bin/env bash' 'if command -v setsid >/dev/null; then setsid pAntler mission.moos & fi' > "$fixture/platform_launch.sh"
printf '%s\n' '#!/usr/bin/env bash' 'uname >/dev/null' 'lsof -n -P -d cwd' 'for proc in /proc/[0-9]*; do :; done' > "$fixture/stop.sh"

portable_output="$(bash "$checker" "$fixture" || true)"
if grep -Fq 'warning: launcher uses setsid without an availability check' <<<"$portable_output"; then
  echo "unexpected setsid warning with availability check" >&2
  exit 1
fi
if grep -Fq 'warning: stop.sh uses /proc without an obvious non-Linux fallback' <<<"$portable_output"; then
  echo "unexpected /proc warning with non-Linux fallback" >&2
  exit 1
fi

echo "PASS mission portability warnings"
