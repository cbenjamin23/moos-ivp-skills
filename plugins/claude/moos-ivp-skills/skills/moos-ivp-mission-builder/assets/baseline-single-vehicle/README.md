# Baseline Single-Vehicle Mission

One simulated vehicle named `abe` runs a waypoint survey, can return to the
operator-selected point, and can station keep. The shoreside community provides
`pMarineViewer` buttons for deploy, return, and station keeping.

## Run

Generate targets only:

```bash
./launch.sh --just_make --nogui 5
```

Run headless:

```bash
./launch.sh --nogui 5
```

Run with GUI:

```bash
./launch.sh 5
```

## Files

- `launch.sh` launches the full mission.
- `launch_vehicle.sh` launches one vehicle community.
- `launch_shoreside.sh` launches the shoreside community.
- `meta_vehicle.moos` configures vehicle MOOS apps.
- `meta_vehicle.bhv` configures helm behaviors.
- `meta_shoreside.moos` configures shoreside apps and operator buttons.

## Operator Action

In `pMarineViewer`, press `DEPLOY` to start the survey. Press `RETURN` to send
the vehicle home or use the left-click return-point context action when the GUI
is available.

