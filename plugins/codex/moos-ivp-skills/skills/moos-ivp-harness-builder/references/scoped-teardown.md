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
  . "$TEARDOWN_HELPER"
else
  echo "$ME: Missing teardown helper: $TEARDOWN_HELPER"
  exit 1
fi

stop_mission_apps() {
  local mission_root="$1"
  moos_scoped_teardown_stop_root "$mission_root" >/dev/null 2>&1 || true
}

cleanup() {
  if [ -n "${RUN_ROOT:-}" ] && [ -d "$RUN_ROOT" ]; then
    stop_mission_apps "$RUN_ROOT"
    if [ "$KEEP_WORKDIRS" != "yes" ]; then
      rm -rf "$RUN_ROOT"
    fi
  fi
}

trap cleanup EXIT
```

Keep every helper call scoped to the temp root, case directory, or stem mission
directory owned by the harness.

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
