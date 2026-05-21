# Baseline Two-Vehicle Mission

The bundled baseline in `assets/baseline-two-vehicle/` is a portable
two-vehicle shoreside mission scaffold.

## Design

- Vehicle communities: `alpha`, `bravo`
- Shoreside community: `shoreside`
- One reusable `launch_vehicle.sh`
- Top-level `launch.sh` loops over vehicle arrays
- Distinct MOOSDB and pShare ports per vehicle
- Colon-separated `VNAMES` passed to the shoreside launcher
- Viewer: `MIT_SP.tif` with `DEPLOY`, `STATION`, `RETURN`, and `ALLSTOP`
  operator buttons applying to all vehicles
- Operator visibility apps: `pRealm`, `uProcessWatch`, `uLoadWatch`, and
  `uFldNodeComms`

## Copying

Copy the asset directory into the requested mission location, then edit:

- author name in headers
- mission title in `README.md`
- vehicle arrays in `launch.sh`
- waypoint polygons and return points
- colors, names, speeds, and ports
- app stack and behavior blocks

The launcher files are intended to be copied almost directly. Preserve one
`launch_vehicle.sh` and one `launch_shoreside.sh`. For more vehicles, extend the
arrays in `launch.sh`; do not create per-vehicle launcher scripts unless the
existing project already uses that convention.

## Port Pattern

Defaults:

- shoreside: MOOSDB `9000`, pShare `9200`
- `alpha`: MOOSDB `9001`, pShare `9201`
- `bravo`: MOOSDB `9002`, pShare `9202`

If adding vehicles, continue the same compact sequence unless the surrounding
repo already uses a different mission port convention.

## Generated Targets

A successful `--just_make` run should create:

- `targ_alpha.moos`
- `targ_alpha.bhv`
- `targ_bravo.moos`
- `targ_bravo.bhv`
- `targ_shoreside.moos`

Each vehicle target should contain its own `ServerPort`, `Community`, pShare
listen route, and `behaviors = targ_<name>.bhv`.
