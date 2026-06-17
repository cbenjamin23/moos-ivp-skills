---
name: moos-ivp-mission-builder
description: "Build or repair the ordinary mission layer for one standalone MOOS-IvP mission: launchers, meta files, helm layout, communities, ports, nsplug targets, viewer setup, and README updates. For self-evaluating missions, use moos-ivp-eval-mission-builder as the primary skill."
---

# MOOS-IvP Mission Builder

## Overview

Use this skill for one ordinary mission folder: launchers, meta files, helm
behavior layout, mission README, and target generation. The mission may be
headless-capable, but it should remain human-readable and runnable on its own.
Optimize for the quality of that single mission, not for batch execution.

For custom app config surfaces, use `moos-app-builder`. For custom behavior
config surfaces, use `ivp-behavior-builder`. For upstream app or behavior
parameters not already clear from the chosen baseline or local repo convention,
use `moos-ivp-docs`. For post-mission analysis, use `moos-alog-analysis`.

## Core Rules

- Prefer copying `assets/baseline-single-vehicle/` or
  `assets/baseline-two-vehicle/` and adapting it over writing launchers from
  scratch.
- Treat bundled launch scripts as near-copy templates. Change names, defaults,
  mission-specific parameters, app runs, and forwarded arguments as needed, but
  preserve the launcher structure unless the existing project has a stronger
  local convention.
- Keep `launch.sh`, `launch_vehicle.sh`, `launch_shoreside.sh`, and `clean.sh`
  convention-bound. Preserve their `Part N` structure and help summaries.
- Keep `launch.sh` as the human-facing mission-level launcher.
- Keep sublaunchers thin: each sublauncher generates one community and launches
  it unless `--just_make` is set.
- Let top-level `launch.sh` own interactive `uMAC`; pass `--auto` into
  sublaunchers so they do not open nested `uMAC` sessions.
- Use `--just_make` as the first validation path. It proves target generation,
  not runtime app validity.
- Include caller-controlled port overrides when adding or repairing launchers:
  `--shore_mport`, `--shore_pshare`, `--veh_mport`, and `--veh_pshare` for a
  one-vehicle mission. These make the mission easy to run beside other local
  MOOS work and easy to validate on non-default ports.
- Use `nsplug --strict --force -x` in launchers so `.moosx` / `.bhvx` sidecars
  are honored when an operator or local repo uses sidecar overrides.
- Launchable mission examples should include `ProcessConfig = ANTLER` with the
  `Run = ...` roster. A standalone `ProcessConfig = <AppName>` block is
  appropriate only for intentional snippets or app help text.
- Treat plug files as discretionary style. Follow the local repo convention:
  keep small missions readable with direct `ProcessConfig` blocks unless a plug
  file clearly removes shared duplication or the project already uses plug
  files.
- Keep `.moos` and `.bhv` files in the local boxed-header style:

  ```text
  //-------------------------------------------------
  // FILE: <filename>
  // NAME: <author>
  //-------------------------------------------------
  ```

- Use `//----------------------------------------------------` for internal
  section dividers between `ProcessConfig` or `Behavior` blocks.
- Add a short `README.md` with scenario, files, common run commands, and
  expected operator action.
- Do not add `pAutoPoke`, `pMissionEval`, `uMayFinish`, case loops, matrix
  execution, or result aggregation here unless the user explicitly asks for a
  self-evaluating test mission. They are not part of an ordinary standalone
  mission.

## Workflow

1. Resolve the mission shape.
   - single vehicle vs multiple vehicles
   - simulated vehicle vs hardware/interface app
   - shoreside/vehicle split vs standalone community
   - GUI required vs headless-capable
   - custom app or behavior integration needs
2. Start from `assets/baseline-single-vehicle/` for one vehicle or
   `assets/baseline-two-vehicle/` for two vehicles unless the existing repo
   already has a closer mission family.
3. Read `references/mission-style.md` before editing launchers or meta files.
4. Read `references/baseline-single-vehicle.md` or
   `references/baseline-two-vehicle.md` before adapting a bundled baseline.
5. Edit the mission files for the requested scenario.
   - Keep the wrapper skeleton intact.
   - Add only the MOOS apps needed for the mission.
   - Keep behavior blocks small and named clearly.
   - Preserve port override plumbing end to end.
6. Add or update `README.md`.
7. Validate with `./launch.sh --just_make --nogui <warp>`.
8. Inspect generated `targ_*.moos` and `targ_*.bhv`.
9. Run live mission validation only if requested or necessary for the change.
   - When runtime correctness matters, use `references/validation.md` to define
     the live and post-run `.alog` evidence needed before calling the mission
     clean.

## Reference Use

- Read `references/mission-style.md` for wrapper and file-style rules.
- Read `references/baseline-single-vehicle.md` for the bundled baseline design.
- Read `references/validation.md` before reporting a mission as done.
- Use `scripts/static_check_mission.sh <mission-dir>` for a quick structural
  check after creating a mission.
- Use `scripts/check_generated_ports.sh <mission-dir> --port_base=<base>` to
  verify that non-default port overrides are reflected in generated targets.
  Add `--keep-targets` when you need to inspect the generated files afterward.

## Validation Checklist

- `launch.sh --help`, `launch_vehicle.sh --help`, and
  `launch_shoreside.sh --help` describe the real arguments.
- `./launch.sh --just_make --nogui <warp>` succeeds.
- Non-default port target generation succeeds, for example with
  `scripts/check_generated_ports.sh`.
- Generated targets include the intended ports, community names, apps, behavior
  file name, and `MOOSTimeWarp`.
- The top-level launcher opens at most one `uMAC` session.
- Sublaunchers receive `--auto` from top-level `launch.sh`.
- `clean.sh` removes generated targets and logs but does not call `ktm`,
  `pkill`, or mission-specific teardown.
- `README.md` explains how to run the mission.
