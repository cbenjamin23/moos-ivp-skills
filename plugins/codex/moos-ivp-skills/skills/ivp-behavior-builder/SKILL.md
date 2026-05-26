---
name: ivp-behavior-builder
description: Build or modify user-owned IvP helm behaviors outside the core MOOS-IvP source tree. Use when an AI coding agent needs to create a C++ BHV_* behavior, implement IvPBehavior lifecycle methods, build a behavior shared library, make pHelmIvP find behavior libraries through IVP_BEHAVIOR_DIRS, or add .bhv mission configuration for a custom helm behavior.
---

# IvP Behavior Builder

## Overview

Use this skill for custom IvP helm behavior development against the local MOOS-IvP checkout. Treat MOOS-IvP as the dependency and example source unless the user explicitly asks to patch core MOOS-IvP.

## MOOS-IvP Checkout Resolution

When this skill needs a local MOOS-IvP checkout, resolve it in this order:

1. Path explicitly provided by the user.
2. `MOOS_IVP_ROOT` from the shell environment.
3. Active task workspace if it contains `ivp/src`.
4. Parent or sibling directories near the active task workspace.
5. Common home locations such as `~/moos-ivp`, `~/src/moos-ivp`, `~/repos/moos-ivp`, and `~/projects/moos-ivp`.
6. A bounded shallow home search for a directory named `moos-ivp`, excluding noisy folders.

Validate a candidate by confirming `ivp/src` exists and `scripts/GenBehavior` is executable.

If no valid checkout is found and the task requires behavior source generation, build wiring, examples, headers, or libraries, stop and ask the user for the checkout path before editing code, generating build files, or using placeholder paths.

## Core Rules

- Default new behaviors to third-party dynamic shared libraries in the user project.
- Do not add new behavior source to core `ivp/src/lib_behaviors*` unless the user explicitly asks to modify core MOOS-IvP.
- Use `$MOOS_IVP_ROOT/scripts/GenBehavior` when there is no close existing behavior to copy.
- Run `GenBehavior` only in a clean behavior source location; it appends to `BHV_<Name>.h/.cpp` if those files already exist.
- Name behavior files and classes `BHV_<Name>.h/.cpp` and `BHV_<Name>`.
- Export `createBehavior` for dynamic loading.
- Build dynamic behaviors as shared libraries named so the output is `libBHV_<Name>.dylib` on macOS or `libBHV_<Name>.so` on Linux.
- Ensure `pHelmIvP` can find the library. Default to the user's shell convention: add the project `lib` directory to `IVP_BEHAVIOR_DIRS`, usually in `.bashrc` or the user's equivalent shell startup file when they ask for persistent setup. Use mission-local `ivp_behavior_dir = <project>/lib` only when the user explicitly wants a self-contained mission, non-interactive execution cannot assume shell setup, or an existing mission already uses that convention.
- Use `.bhv` blocks for mission configuration; do not bake mission-specific parameters into the constructor.
- Call `IvPBehavior::setParam(param, val)` first when the behavior should accept standard behavior parameters.
- Apply `m_priority_wt` to returned IvP functions.
- Use `postWMessage()` or `postEMessage()` for behavior warnings/errors instead of silent failure.
- Preserve the generator-style metadata comment box at the top of source files and update `NAME`, `ORGN`, `FILE`, and `DATE` to match the user project.
- Use short comments before non-obvious behavior logic; do not add comments that merely restate simple code.
- Reuse existing MOOS-IvP behavior, IvP build, geometry, contact, and utility libraries before writing custom parsers, objective-function machinery, or geometry math.
- Do not commit or present build directories/binaries as source changes unless the user's project already tracks generated artifacts.

## Workflow

1. Choose the behavior shape.
   - Default to the simplest shape that matches the requested effect.
   - Posting-only behavior: use when the behavior should publish state/flags but not influence helm decisions.
   - Single decision variable objective: use ZAIC, for example speed-only, course-only, or depth-only.
   - Coupled multi-variable objective: use AOF plus Reflector only when utility genuinely depends on multiple decision variables together.
   - Contact-relative behavior: use `IvPContactBehavior` only for behaviors centered on another vehicle/contact.
2. Choose the starting point.
   - New simple behavior: create and enter the behavior library source directory, then run `GenBehavior <Name> "<Author>"` there.
   - Inspect similar behaviors as references. Copy a behavior when the user explicitly asks or when it is obviously the nearest local-project base.
3. Wire the build.
   - Read `references/behavior-build.md`.
   - Add or update an `ADD_LIBRARY(BHV_<Name> SHARED ...)` block.
4. Implement lifecycle.
   - Read `references/behavior-patterns.md`.
   - Constructor: descriptor/defaults, `subDomain`, `addInfoVars`.
   - `setParam`: replace the generator placeholder so standard params are accepted through `IvPBehavior::setParam(param, val)` before custom parsing.
   - `onSetParamComplete`: validate required and interdependent params.
   - `onRunState`: read info-buffer state, build/post output, return an `IvPFunction*` or `0`.
5. Implement IvP function construction if needed.
   - Read `references/ivp-function-patterns.md`.
6. Add mission integration only when needed. Use `moos-ivp-mission-builder`
   when the task expands into ordinary mission launchers, ANTLER rosters,
   vehicle/shoreside layout, or pMarineViewer operator controls.
   - Add a `Behavior = BHV_<Name>` block in the relevant `.bhv`.
   - Ensure helm mission files have required geodesy context such as `LatOrigin` and `LongOrigin`; missing origins can put `pHelmIvP` in `MALCONFIG` before behavior loading is exercised.
   - Prefer adding the behavior library directory to `IVP_BEHAVIOR_DIRS` when persistent shell setup is in scope.
   - Add `ivp_behavior_dir = <project>/lib` to `pHelmIvP` config only for explicit self-contained, non-interactive, or existing-mission-convention cases.
7. Validate.
   - Configure/build the project.
   - Confirm the shared library lands in the project `lib/`.
   - Confirm the shared library exports `createBehavior` before runtime loading.
   - If mission config changed, verify `pHelmIvP` can load the behavior through
     a normal `pAntler` mission launch when feasible. Treat direct `pHelmIvP`
     execution as a narrow fallback only; if used, launch with app name
     `pHelmIvP` on `PATH` or pass `--alias=pHelmIvP` so the process reads
     `ProcessConfig = pHelmIvP`.
   - For isolated runtime tests, set `IVP_BEHAVIOR_DIRS` to only the generated
     project `lib` directory unless inherited behavior dirs are part of the
     test.

## Reference Use

- Read `references/behavior-build.md` before writing behavior CMake or mission loading lines.
- Read `references/behavior-patterns.md` before implementing lifecycle methods.
- Read `references/ivp-function-patterns.md` before building an objective function.
- Read `references/behavior-examples.md` when choosing local examples to inspect.

## Validation Checklist

- Shared library builds with the expected `libBHV_*` name.
- Standard behavior params still work.
- Required custom params are validated.
- `addInfoVars()` covers every info-buffer variable read by the behavior.
- `onRunState()` handles missing or stale info-buffer values explicitly.
- Returned IPF has `m_priority_wt` applied.
- Mission `.bhv` block uses behavior type `BHV_<Name>` and a unique `name`.
- Behavior library path is available to `pHelmIvP`.
- Shared library exposes `createBehavior` as a dynamic symbol.
- Runtime load checks look for explicit success such as `About to load behavior library: BHV_<Name> ... SUCCESS`, `BehaviorSet: all_builds_ok: true`, or equivalent appcast/console confirmation.
