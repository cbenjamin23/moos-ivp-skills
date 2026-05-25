# Baseline Single-Vehicle Mission

The bundled baseline in `assets/baseline-single-vehicle/` is a portable
one-vehicle shoreside mission scaffold.

## Design

- Vehicle community: `abe`
- Shoreside community: `shoreside`
- Vehicle apps: `pRealm`, `uProcessWatch`, `uLoadWatch`, `uSimMarineV22`,
  `pMarinePIDV22`, `pNodeReporter`, `uFldNodeBroker`, `pHelmIvP`,
  `pLogger`, `pShare`, `pHostInfo`
- Shoreside apps: `uFldShoreBroker`, `pMarineViewer` when GUI is enabled,
  `uFldNodeComms`, `pRealm`, `uProcessWatch`, `uLoadWatch`, `pLogger`,
  `pShare`, `pHostInfo`
- Viewer: `MIT_SP.tif` with `DEPLOY`, `STATION`, `RETURN`, and `ALLSTOP`
  operator buttons
- Helm behaviors: survey waypoint, return waypoint, station keep

## Copying

Copy the asset directory into the requested mission location, then edit:

- author name in headers
- mission title in `README.md`
- waypoint polygon or point
- vehicle name/color
- app stack
- behavior blocks
- pMarineViewer map/pan/zoom if needed

The launcher files are intended to be copied almost directly. Preserve the
`Part N` sections, argument style, `--just_make`, `--auto`, `--xlaunched`,
`--nogui`, and port forwarding. Add mission parameters by extending the existing
argument blocks and forwarding arrays rather than rewriting the launch flow.

## Adapting To Custom Apps

For a custom vehicle app, add it to `meta_vehicle.moos`:

```text
Run = pMyApp @ NewConsole = false
```

Then add a `ProcessConfig = pMyApp` block and any needed subscriptions or
publications in the app implementation. Keep mission config values lowercase
snake case unless the app already uses another convention.

For a custom shoreside app, add it to `meta_shoreside.moos`.

## Adapting To Custom Behaviors

For a custom behavior library, add a `Behavior = BHV_Name` block in
`meta_vehicle.bhv`. Prefer making the behavior library visible through
`IVP_BEHAVIOR_DIRS`, usually via the user's shell startup convention. Add an
`ivp_behavior_dir = <path>` line to the `pHelmIvP` block only when the user
explicitly wants a self-contained mission, the run environment cannot assume
shell setup, or the existing mission already uses that convention.

## Multi-Vehicle Changes

Prefer `assets/baseline-two-vehicle/` when the requested mission has two
vehicles. Do not casually stretch this one-vehicle baseline by copy/pasting
whole sublaunchers.
