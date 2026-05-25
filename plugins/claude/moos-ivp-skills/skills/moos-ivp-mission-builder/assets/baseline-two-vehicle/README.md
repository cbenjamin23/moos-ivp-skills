# Baseline Two-Vehicle Mission

Two simulated vehicles, `alpha` and `bravo`, run separate waypoint survey
boxes from one shoreside community. The vehicles share one
`launch_vehicle.sh` path, with `launch.sh` looping over the vehicle defaults.

Default ports and colors:

- `alpha`: MOOSDB `9001`, pShare `9201`, color `yellow`
- `bravo`: MOOSDB `9002`, pShare `9202`, color `red`
- `shoreside`: MOOSDB `9000`, pShare `9200`

## Run

Generate targets only:

```bash
./launch.sh --just_make --nogui 2
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
- `launch_vehicle.sh` launches one vehicle community and is reused for both
  `alpha` and `bravo`.
- `launch_shoreside.sh` launches the shoreside community.
- `meta_vehicle.moos` configures vehicle MOOS apps.
- `meta_vehicle.bhv` configures helm behaviors.
- `meta_shoreside.moos` configures shoreside apps and operator buttons.

## Operator Action

In `pMarineViewer`, press `DEPLOY` to start the survey. Press `RETURN` to send
the vehicle home or use the left-click return-point context action when the GUI
is available.

## Adaptation Notes

Keep one `launch_vehicle.sh`. Add vehicles by extending the arrays in
`launch.sh`; do not create one launcher per vehicle.
