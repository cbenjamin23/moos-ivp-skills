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

The baseline reports `BHV_WARNING_SEEN` as evidence but does not make that field
part of the verdict. If a derived eval is behavior-specific and should reject
any warning, add `pass_condition = BHV_WARNING_SEEN = false` deliberately and
document the stricter contract.

On current tested MOOS-IvP builds, this starter mission may report
`bhv_warning=true` from a transient pHelmIvP waypoint warning even when the
generated behavior file contains the waypoint and the mission completes. Treat
that as known baseline evidence; investigate new, repeated, or scenario-specific
warnings before deciding whether they should become pass conditions.

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
- `zlaunch.sh` calls shared `xlaunch.sh` for headless evaluation.
- `meta_vehicle.moos` configures vehicle MOOS apps.
- `meta_vehicle.bhv` configures helm behaviors.
- `meta_shoreside.moos` configures shoreside apps, evaluator apps, and buttons.

## Operator Action

In `pMarineViewer`, the mission auto-deploys to the evaluated waypoint. Press
`ALLSTOP` to stop the run during manual inspection.
