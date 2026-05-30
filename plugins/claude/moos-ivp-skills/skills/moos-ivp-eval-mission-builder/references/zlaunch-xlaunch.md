# `zlaunch.sh` And `xlaunch.sh`

`zlaunch.sh` is the mission-local automation wrapper. It should not become a
mini harness.

It also must not become the grader. The final `grade=` row should be written by
`pMissionEval`, not by shell code reading `targ_*.moos`, interpreting a
`grade_hint`, or echoing a synthetic result.

## Thin Wrapper Pattern

```bash
#!/bin/bash
ME=`basename "$0"`
TIME_WARP=10
MAX_TIME=90
NOGUI="--nogui"
JUST_MAKE=""
VERBOSE=""
MMOD=""

for ARGI; do
  if [ "${ARGI}" = "--gui" ]; then
    NOGUI=""
  elif [ "${ARGI}" = "--nogui" -o "${ARGI}" = "-ng" ]; then
    NOGUI="--nogui"
  elif [ "${ARGI}" = "--just_make" -o "${ARGI}" = "-j" ]; then
    JUST_MAKE="--just_make"
  elif [ "${ARGI:0:11}" = "--max_time=" ]; then
    MAX_TIME="${ARGI#--max_time=*}"
  elif [ "${ARGI:0:7}" = "--mmod=" ]; then
    MMOD="${ARGI#--mmod=*}"
  elif [ "${ARGI//[^0-9]/}" = "$ARGI" -a "$TIME_WARP" = 10 ]; then
    TIME_WARP=$ARGI
  else
    echo "$ME: Bad arg: $ARGI"
    exit 1
  fi
done

: > results.txt
xlaunch.sh --max_time=$MAX_TIME $NOGUI $JUST_MAKE $VERBOSE \
  ${MMOD:+--mmod=$MMOD} $TIME_WARP
status=$?

if [ "${JUST_MAKE}" = "" ]; then
  for try in 1 2 3; do
    grep -q 'grade=' results.txt 2>/dev/null && break
    sleep 1
  done
  if ! grep -q 'grade=' results.txt 2>/dev/null; then
    echo "$ME: results.txt does not contain a grade= result"
    status=1
  fi

  repo_dir=`git -C "$PWD" rev-parse --show-toplevel 2>/dev/null`
  TEARDOWN_HELPER="$repo_dir/scripts/moos_scoped_teardown.sh"
  if [ "$repo_dir" = "" ] || [ ! -x "$TEARDOWN_HELPER" ]; then
    echo "$ME: Missing scoped teardown helper: scripts/moos_scoped_teardown.sh"
    status=1
  else
    "$TEARDOWN_HELPER" "$PWD" || status=1
  fi
fi
```

The mission-local `MAX_TIME` is only a shell default. The shared `xlaunch.sh`
receives the final value through `--max_time=<secs>` and passes it to
`uMayFinish`; it is not a `.moos` or `pMissionEval` configuration variable.

## Cleanup

For eval missions that need a cleanup backstop, copy
`assets/moos_scoped_teardown.sh` from this skill into the target project as
`<project-root>/scripts/moos_scoped_teardown.sh` if that script does not already
exist. Source or call that helper from `zlaunch.sh` after `xlaunch.sh`, passing
the mission directory or temp root. The goal is to keep cleanup scoped to the
mission run without requiring files from the skill directory at runtime.

If a portable fallback is truly necessary, filter to known MOOS app process
names or recorded child PIDs. Do not blindly pipe every PID from `lsof +D
"$PWD"` to `kill`; that can match the invoking shell or audit commands. Do not
add global `ktm`, broad `pkill`, or machine-wide process sweeps.

## Common Mistakes

- Reimplementing `uMayFinish` in `zlaunch.sh`.
- Reimplementing completion polling when `xlaunch.sh` already owns completion.
  The wrapper should still assert that the final report contains `grade=`.
- Trusting the wrapper exit code without confirming `results.txt` contains
  `grade=`. A timeout can produce no mission evaluation, so a public wrapper
  should wait briefly for the result row, then turn missing `grade=` into a
  nonzero exit.
- Treating `zlaunch.sh` exit `0` as equivalent to `grade=pass`. In harness use,
  exit `0` means the mission produced a result row; the caller must parse
  `grade=`. A mission-owned `grade=fail` should remain available to the harness
  as evidence, not be collapsed into `launch_error`.
- Echoing or printing `grade=` from the wrapper. That hides whether the mission
  actually evaluated itself.
- Adding `--case` or `--jobs`; that turns the wrapper into a harness.
- Hard-coding private absolute paths to `xlaunch.sh` or teardown scripts.
