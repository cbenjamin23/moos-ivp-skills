# Eval Single-Vehicle Mission

One simulated vehicle named `abe` auto-deploys to a waypoint and self-grades
when the waypoint behavior completes. The mission remains GUI-capable for
inspection, but the normal automation path is headless `zlaunch.sh`.

This asset is a single-machine simulation template. The launcher keeps IP
arguments for normal MOOS launcher shape, but the pShare route setup assumes all
communities are on the local host.

## Evaluation

`pAutoPoke` starts the mission and initializes evaluation variables.
`pMissionEval` uses the waypoint completion event as its lead condition and
writes `results.txt` when that event occurs. `zlaunch.sh` forwards
`--max_time` to `xlaunch.sh`, which runs `uMayFinish` as the outer
infrastructure ceiling.

The passing baseline requires:

- `WPT_DONE=true`
- `WPT_HIT=true`
- `CYCLE_HIT=true`
- `WAYPOINT_END=true`
- `BHV_ERROR_SEEN=false`

The baseline does not report a sticky `BHV_WARNING_SEEN` result field.
`BHV_WARNING` traffic is useful development evidence, but transient or retracted
helm warnings should not become part of the default mission verdict. Investigate
warnings during validation with appcasts or `.alog` tools; only add a warning
metric deliberately when the scenario is explicitly warning-intolerant and the
warning signal is known to be stable.

## Run

Generate targets only:

```bash
./launch.sh --just_make --nogui 5
```

Run the self-evaluating headless cycle:

```bash
./zlaunch.sh --max_time=60 10
```

Run with GUI for visual inspection:

```bash
./launch.sh 5
```

## Files

- `launch.sh` launches the full mission.
- `launch_vehicle.sh` launches one vehicle community.
- `launch_shoreside.sh` launches the shoreside community.
- `zlaunch.sh` calls shared `xlaunch.sh` for headless evaluation, then uses
  `<project-root>/scripts/moos_scoped_teardown.sh` as a scoped cleanup backstop.
- `meta_vehicle.moos` configures vehicle MOOS apps.
- `meta_vehicle.bhv` configures helm behaviors.
- `meta_shoreside.moos` configures shoreside apps, evaluator apps, and buttons.

## Operator Action

In `pMarineViewer`, the mission auto-deploys to the evaluated waypoint. Press
`ALLSTOP` to stop the run during manual inspection.
