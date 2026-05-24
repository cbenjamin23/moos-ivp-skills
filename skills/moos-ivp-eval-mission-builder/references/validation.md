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
  the selected `--gui` or `--nogui` mode

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
- logs are free of unexpected config, deprecation, and runtime warnings
- no leftover MOOSDB or pShare process remains for the mission

Use `moos-alog-analysis` for targeted post-run evidence when the mission grade
is not enough to understand what happened.

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
