#!/usr/bin/env bash
set -u

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "missing project directory: $PROJECT_DIR" >&2
  exit 2
fi

FIXED_ROOT_RE='(/opt/moos-ivp|/Users/[^/[:space:]]+/[^[:space:]]*moos-ivp|/home/[^/[:space:]]+/[^[:space:]]*moos-ivp)'
WARNINGS=0

while IFS= read -r -d '' FILE; do
  if grep -Iq . "$FILE" && grep -Eq -- "$FIXED_ROOT_RE" "$FILE"; then
    RELATIVE_FILE="${FILE#"$PROJECT_DIR"/}"
    echo "warning: $RELATIVE_FILE contains a fixed MOOS-IvP checkout path; supply MOOS_IVP_ROOT at configuration time or through the caller environment"
    WARNINGS=$((WARNINGS + 1))
  fi
done < <(
  find "$PROJECT_DIR" \
    \( -type d \( -name .git -o -name build -o -name 'build-*' -o -name 'cmake-build-*' -o -name logs -o -name 'LOG_*' \) -prune \) -o \
    -type f -print0
)

if [ "$WARNINGS" -eq 0 ]; then
  echo "PASS no fixed MOOS-IvP checkout paths found outside ignored build/log directories"
fi

exit 0
