# Scoped Teardown

Use this guidance when writing cleanup code for a harness launcher. Harness
cleanup should only stop MOOS processes that belong to the stem mission copy or
temp-run root created by that harness run.

For generated harnesses, copy the skill asset `assets/moos_scoped_teardown.sh`
into the target project as `<project-root>/scripts/moos_scoped_teardown.sh`
unless the project already has an equivalent root-scoped helper. Make it
executable, source it from harness launchers, and pass it the harness-owned
mission directory, case directory, or run root.

## Preferred Shape

```bash
# Use ../../.. for harnesses/<family>_harnesses/<name>;
# use ../.. for harnesses/<name>.
REPO_DIR="$(cd "$HARNESS_DIR/../../.." && pwd)"
TEARDOWN_HELPER="$REPO_DIR/scripts/moos_scoped_teardown.sh"

if [ -f "$TEARDOWN_HELPER" ]; then
  # shellcheck source=/dev/null
  . "$TEARDOWN_HELPER"
else
  echo "$ME: Missing teardown helper: $TEARDOWN_HELPER"
  exit 1
fi

stop_mission_apps() {
  local mission_root="$1"
  moos_scoped_teardown_stop_root "$mission_root" >/dev/null
}

CLEANED=no
CLEANING=no
CLEANUP_FAILED=no

cleanup_runtime() {
  local root_stopped=yes
  [ "$CLEANED" = no ] || return 0
  [ "$CLEANING" = no ] || return 0
  CLEANING=yes
  trap '' INT TERM PIPE

  if [ -n "${RUN_ROOT:-}" ] && [ -d "$RUN_ROOT" ]; then
    if ! stop_mission_apps "$RUN_ROOT"; then
      echo "$ME: teardown failed; preserving run root: $RUN_ROOT" >&2
      root_stopped=no
      CLEANUP_FAILED=yes
    fi
    if [ "$KEEP_WORKDIRS" != "yes" ] && [ "$root_stopped" = "yes" ] &&
       [ "$CLEANUP_FAILED" = "no" ]; then
      rm -rf "$RUN_ROOT"
    fi
  fi
  CLEANED=yes
  CLEANING=no
}

cleanup() {
  local status=$?
  cleanup_runtime
  [ "$CLEANUP_FAILED" = "no" ] || [ "$status" -ne 0 ] || status=1
  exit "$status"
}

trap cleanup EXIT
```

Keep every helper call scoped to the temp root, case directory, or stem mission
directory owned by the harness.

Do not hide helper stderr or discard its status. A cleanup trap should preserve
an existing failure or signal status, turn an otherwise successful run into a
failure when teardown cannot be verified, and keep the run root when teardown
fails.

If `cleanup_runtime` is also called explicitly before the final verdict, use
both the `CLEANING` re-entry guard and `CLEANED` idempotence guard shown above.
Once cleanup begins, ignore further `INT`, `TERM`, and `PIPE` signals so
repeated interrupts cannot stop teardown or run-root removal.

When a helper exposes shell functions, source it and call the root-scoped
function rather than invoking a broad cleanup command:

```bash
source "$REPO_DIR/scripts/moos_scoped_teardown.sh"
moos_scoped_teardown_stop_root "$RUN_ROOT"
```

Portable fallback cleanup should still be root-scoped, for example by recording
child PIDs when launching each case. Avoid rewriting process discovery in each
harness when the asset helper can be copied instead.

Do not pipe every PID from `lsof +D "$RUN_ROOT"` directly to `kill`; that can
match the invoking shell or audit tools whose current directory is under the run
root. If process discovery is unavoidable, filter to known MOOS app process
names and require their cwd to be under the harness-owned root, as the asset
helper does.

## Avoid

- `ktm`
- broad `pkill` patterns
- `killall MOOSDB`
- cleanup that can stop unrelated local MOOS work

Global cleanup hides port bugs and makes it unsafe to run a harness beside
another mission.
