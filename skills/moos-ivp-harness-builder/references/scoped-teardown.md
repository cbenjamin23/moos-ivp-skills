# Scoped Teardown

Harness cleanup should be bounded to the mission or temp-run root it created.

## Preferred Shape

```bash
cleanup() {
  if [ -n "${RUN_ROOT:-}" ] && [ -d "$RUN_ROOT" ]; then
    if [ -x "$TEARDOWN_HELPER" ]; then
      "$TEARDOWN_HELPER" "$RUN_ROOT"
    fi
    if [ "$KEEP_WORKDIRS" != "yes" ]; then
      rm -rf "$RUN_ROOT"
    fi
  fi
}

trap cleanup EXIT
```

Use a repository helper when available, but keep the call scoped to the temp
root or mission directory.

When a helper exposes shell functions, source it and call the root-scoped
function rather than invoking a broad cleanup command:

```bash
source "$REPO_DIR/scripts/harness_teardown.sh"
harness_teardown_stop_root "$RUN_ROOT"
```

Portable fallback cleanup should still be root-scoped, for example by selecting
only known MOOS app processes holding files under the harness-owned run root.
Do not pipe every PID from `lsof +D "$RUN_ROOT"` directly to `kill`; that can
match the invoking shell or audit tools whose current directory is under the
run root. Filter to known MOOS app process names or, better, record child PIDs
when launching each case.

## Avoid

- `ktm`
- broad `pkill` patterns
- `killall MOOSDB`
- cleanup that can stop unrelated local MOOS work

Global cleanup hides port bugs and makes it unsafe to run a harness beside
another mission.
