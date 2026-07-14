# Mission Style Reference

## File Set

A normal one-vehicle shoreside mission should usually include:

- `launch.sh`
- `launch_vehicle.sh`
- `launch_shoreside.sh`
- `clean.sh`
- `plug_origin_warp.moos`
- `meta_vehicle.moos`
- `meta_vehicle.bhv`
- `meta_shoreside.moos`
- `README.md`

## Launcher Roles

`launch.sh` is the human-facing mission launcher. It parses high-level mission
arguments, invokes vehicle and shoreside sublaunchers with `--auto`, and owns
the single interactive `uMAC` session unless `--xlaunched` is used.

`launch_vehicle.sh` generates `targ_<vname>.moos` and `targ_<vname>.bhv`, then
launches that vehicle community unless `--just_make` is set.

`launch_shoreside.sh` generates `targ_shoreside.moos`, then launches the
shoreside community unless `--just_make` is set.

`clean.sh` removes generated files and logs only. It should not kill processes.

## Copying Launchers

The bundled launchers are style templates, not loose pseudocode. Copy the
nearest launcher set nearly whole, then make narrow edits:

- update mission name and author
- add or remove mission-specific arguments
- forward new arguments into `nsplug`
- add or remove `Run = ...` lines and matching `ProcessConfig` blocks
- adjust vehicle arrays for multi-vehicle missions

Avoid rewriting the launch flow, changing ownership of `uMAC`, or removing
`--just_make`, `--auto`, `--xlaunched`, `--nogui`, or port overrides without a
specific reason.

## Port Plumbing

Port overrides are a standalone mission quality feature. They let an operator
run the mission beside other MOOS work, avoid stale listener conflicts, and
validate the launch path without editing source files.

For one vehicle, use explicit defaults and keep them overridable:

- shoreside MOOSDB: `9000`
- vehicle MOOSDB: `9001`
- shoreside pShare: `9200`
- vehicle pShare: `9201`

Top-level `launch.sh` should accept:

- `--shore_mport=<port>`
- `--veh_mport=<port>`
- `--shore_pshare=<port>`
- `--veh_pshare=<port>`

Then it should forward those values into the sublaunchers. Do not leave a port
option parsed at the top level but ignored by a sublauncher.

The generated `pShare` block for each community should use that community's own
pShare listen port:

```text
input = route = localhost:$(PSHARE_PORT)
```

Do not confuse the vehicle's own `PSHARE_PORT` with the shoreside pShare port.
The vehicle uses `SHORE_PSHARE` separately in broker routing such as
`try_shore_host = pshare_route=$(SHORE_IP):$(SHORE_PSHARE)`.

## nsplug

Use strict generation:

```bash
nsplug meta_vehicle.moos targ_$VNAME.moos --strict --force -x ...
```

The `-x` flag honors local `.moosx` or `.bhvx` sidecars when present. This is
useful for operator-local overrides and project-local variants, and it is
harmless when no sidecar exists.

## ANTLER And Config Blocks

Launchable mission examples should include a `ProcessConfig = ANTLER` block.
That block is the pAntler launch roster: its `Run = ...` lines start the apps.
The other `ProcessConfig = <AppName>` blocks configure those apps.

Do not present an app config block alone as a runnable mission. A bare
`ProcessConfig = <AppName>` block is fine for a deliberate snippet, app help
text, or `_Info.cpp` example, but a copyable mission example should include
the ANTLER context or an existing launcher pattern that actually starts the app.

## pMarineViewer

For portable examples, default to an upstream MOOS-IvP map image rather than a
machine-local image path:

- `MIT_SP.tif` for ordinary Charles River/MIT examples
- `forrest19.tif` for COLREGS-style examples when the mission geometry fits it
- `Default.tif`, `DefaultB.tif`, or `AerialMIT.tif` only when a local project
  already uses them or the user asks for a different viewer background

If the mission needs a new custom TIFF rather than an existing MOOS-IvP map,
use the `moos-map-builder` skill; do not create or convert the map manually.

For ordinary operator missions, keep pMarineViewer in its normal process/vehicle
view at startup. Enable appcasting with `appcast_viewable = true`, but do not
force `content_mode = appcast` or set a `realmcast_channel` unless the user is
explicitly building a realmcast-centered mission. Forced InfoCasting can make
normal launched-app stacks appear artificially sparse.

For MIT/Charles River waypoint-style examples on `MIT_SP.tif`, a good default
viewer framing is:

```text
set_pan_x = 5
set_pan_y = -115
zoom      = 1.5
```

Use clean operator button labels. Prefer `DEPLOY`, `STATION`, `RETURN`, and
`ALLSTOP` over labels such as `STATION:true` or `DEPLOY:false`. Put the extra
state changes on later lines for the same button:

```text
button_1 = DEPLOY # DEPLOY_ALL=true
button_1 = MOOS_MANUAL_OVERRIDE_ALL=false
button_1 = RETURN_ALL=false
button_1 = STATION_KEEP_ALL=false

button_2 = STATION # DEPLOY_ALL=true
button_2 = MOOS_MANUAL_OVERRIDE_ALL=false
button_2 = RETURN_ALL=false
button_2 = STATION_KEEP_ALL=true

button_3 = RETURN # RETURN_ALL=true
button_3 = STATION_KEEP_ALL=false

button_4 = ALLSTOP # DEPLOY_ALL=false
button_4 = MOOS_MANUAL_OVERRIDE_ALL=true
```

Use context actions sparingly. For ordinary waypoint missions, a left-click
return-point action is useful when it updates both the return point and return
mode for the clicked vehicle.

## Launched Apps

Keep ordinary mission app stacks operator-visible rather than bare-minimum. A
normal simulated vehicle should usually launch `MOOSDB`, `pRealm`,
`uProcessWatch`, `uLoadWatch`, `pShare`, `pLogger`, `pHostInfo`,
`uSimMarineV22`, `pMarinePIDV22`, `pNodeReporter`, `uFldNodeBroker`, and
`pHelmIvP`. A normal shoreside should usually launch `MOOSDB`, `pRealm`,
`uProcessWatch`, `uLoadWatch`, `pShare`, `pLogger`, `pHostInfo`,
`uFldShoreBroker`, `uFldNodeComms`, and `pMarineViewer` when GUI mode is
enabled.

For ordinary shoreside/vehicle split missions, let `uFldShoreBroker` bridge
`APPCAST_REQ` automatically and let `uFldNodeBroker` carry vehicle `APPCAST`
back to shoreside. Do not add `APPCAST_REQ` to the vehicle broker bridge list;
that direction is wrong for the normal viewer request path.

For ordinary surface simulations with `uSimMarineV22` and `pMarinePIDV22`,
match the common waypoint mission pattern: set `depth_control = false` in
`pMarinePIDV22`, and configure `uSimMarineV22` with `max_speed`,
`max_deceleration`, `turn_rate`, `turn_spd_loss`, `post_des_thrust`, and
`post_des_rudder`. This keeps the helm's `DESIRED_SPEED` and
`DESIRED_HEADING` path connected through PID thrust/rudder into simulated
motion.

Do not add `pAutoPoke`, `pMissionEval`, `uMayFinish`, or `pMissionHash` to an
ordinary mission unless the user asks for self-evaluation. Richer test or
example missions often add `pRealm`, `uProcessWatch`, `uLoadWatch`, `uFldNodeComms`,
and mission-specific monitors, but those should be introduced only when they
serve the requested standalone mission.

## Plug Files

Plug files are discretionary. Do not introduce a general `plugs.moos` file just
because examples exist elsewhere.

Prefer direct `ProcessConfig` blocks in `meta_vehicle.moos` and
`meta_shoreside.moos` when:

- the mission is small
- the block appears once
- clarity matters more than reuse
- the surrounding repo does not already use plug files

Use plug files when:

- the existing repo already uses them
- the same block is shared by several communities or missions
- a small plug improves clarity without hiding mission-specific behavior

The bundled baselines use `plug_origin_warp.moos` only because origin/time-warp
settings are tiny, shared, and easy to audit. This is a convenience, not a
requirement to split other config blocks into plug files.

## Headers

Use this header for mission files:

```text
//-------------------------------------------------
// FILE: meta_vehicle.moos
// NAME: Author Name
//-------------------------------------------------
```

Use this divider between app or behavior blocks:

```text
//----------------------------------------------------
```

## What Not To Put Here

Do not put these in ordinary mission-builder output unless the user explicitly
asks for a self-evaluating test mission:

- `pAutoPoke`
- `pMissionEval`
- `uMayFinish`
- case loops
- `nspatch` sweeps
- result aggregation
- global `ktm` cleanup
