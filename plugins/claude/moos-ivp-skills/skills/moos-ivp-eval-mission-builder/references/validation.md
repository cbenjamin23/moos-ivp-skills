# Eval Mission Validation

Run validation in layers.

## Static

```bash
scripts/static_check_eval_mission.sh <mission-dir>
```

This catches missing files and obvious contract breaks, but it does not prove
runtime behavior.

## Target Generation

```bash
./launch.sh --just_make --nogui 5
```

Inspect generated targets for:

- explicit initialization, such as `pAutoPoke`, `uTimerScript`, or the app under
  test
- `pMissionEval`
- `result_flag = MISSION_EVALUATED = true`
- expected `report_column` entries
- bridged graded variables
- intended port overrides and community names
- whether any `AUTO_LAUNCHED`-guarded evaluator apps are included or excluded
  exactly as intended
- if `mhash=` is reported, `pMissionHash` is present in the generated target for
  headless `--nogui` validation
- GUI targets do not launch both `pMissionHash` and `pMarineViewer` unless the
  pMarineViewer mission-hash feature was explicitly disabled

## Headless Run

```bash
./zlaunch.sh --max_time=120 10
```

Confirm:

- the process exits without manual input
- `results.txt` contains `grade=pass` or the intended failing grade
- for event-driven evals, missing `grade=` after `uMayFinish`/`--max_time` is
  reported as an infrastructure failure
- for time-window evals, expected non-completion paths produce mission-owned
  `grade=fail` before wrapper `--max_time`
- `MISSION_EVALUATED=true` is visible in logs when needed
- logs are inspected for unexpected config, deprecation, and runtime warnings
- no leftover MOOSDB or pShare process remains for the mission
- `<project-root>/scripts/moos_scoped_teardown.sh` exists in the target project
  and is executable, copied from `assets/moos_scoped_teardown.sh` if it was not
  already present

Use `moos-alog-analysis` for targeted post-run evidence when the mission grade
is not enough to understand what happened.

## Live Smoke Helper

For bundled examples and high-trust validation, run the deterministic helper
from this skill:

```bash
scripts/live_check_eval_mission.sh <mission-dir> --port_base=<free-base>
```

It copies the mission to a temp directory, installs the bundled
`moos_scoped_teardown.sh` as a project-root `scripts/` helper, runs
`zlaunch.sh --nogui` on explicit non-default ports, checks the final `grade=`
row, reports `BHV_WARNING` evidence as advisory output, checks for leftover
listeners on the scoped ports, and then cleans up any scoped leftovers it finds.
A failure from this helper means either the mission is not clean or the cleanup
contract needs to be made explicit before distribution.

## GUI Sanity

When the mission remains GUI-capable, run:

```bash
./launch.sh 5
```

Check that normal operator buttons still exist and the viewer is framed on the
mission geometry. Eval additions should not make a normal visual run feel like a
bare automation shell.

Also confirm that a top-level GUI run opens only one `uMAC` session and that a
single Ctrl-C path brings the mission down cleanly.
