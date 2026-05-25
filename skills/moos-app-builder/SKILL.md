---
name: moos-app-builder
description: Build or modify user-owned MOOS applications outside the core MOOS-IvP source tree. Use when an AI coding agent needs to create a new C++ MOOS app, wire it into an extension/project build, implement MOOS mail/config/iterate logic, update app help/interface text, or add mission config for a custom MOOS process.
---

# MOOS App Builder

## Overview

Use this skill for user application development against the local MOOS-IvP checkout. Treat MOOS-IvP itself as the dependency and example source unless the user explicitly asks to patch core MOOS-IvP.

Before using MOOS-IvP paths, resolve `MOOS_IVP_ROOT` from the user's request, `MOOS_IVP_SKILLS_CONFIG`, `~/.config/moos-ivp-skills/config.toml`, the current workspace, or nearby/common checkout locations such as `~/moos-ivp`.

## Core Rules

- Use `GenMOOSApp_AppCasting` for new apps.
- If the project has `src/CMakeLists.txt`, update it with `ADD_SUBDIRECTORY(<app-dir>)`.
- If the project has no build skeleton, create the smallest project-level CMake needed for the new app and point it at the resolved `MOOS_IVP_ROOT`.
- Keep MOOS communication boundaries clear: `OnNewMail()` ingests mail, validates messages, and updates state through `handleMail*` helpers; `Iterate()` owns most business logic, recurring work, and state-derived publications.
- Keep config parsing in `OnStartUp()`, using `handleConfig*` helpers for nontrivial values and AppCasting warnings for bad or unhandled config.
- Keep subscriptions centralized in `registerVariables()` and call `AppCastingMOOSApp::RegisterVariables()` in AppCasting apps.
- Update `_Info.cpp` as part of the app implementation: synopsis, example config, subscriptions, publications, and options must describe the real app.
- Preserve the generator-style metadata comment box at the top of source files and update `NAME`, `ORGN`, `FILE`, and `DATE` to match the user project.
- Use short comments before non-obvious logic blocks; do not add comments that merely restate simple code.
- Reuse existing MOOS-IvP libraries and helpers before writing new parsing, geometry, contact, logic, or AppCasting support code.
- Use local style: MOOS variables are usually uppercase with underscores; mission config params are usually lowercase snake case; C++ members use `m_`; helpers commonly use `handleMail*`, `handleConfig*`, `post*`, `update*`.
- Build and run `--help`, `--example`, and `--interface` as binary smoke checks
  before finishing when feasible. These prove the app starts and its
  self-documentation is wired; they do not prove mission runtime config.
- Do not commit or present build directories/binaries as source changes unless the user's project already tracks generated artifacts.

## Workflow

1. Identify the app role and prefix.
   - `p`: process/control/monitoring app
   - `u`: utility or simulation-support app
   - `uFld`: shoreside field app
   - `i`: interface/driver app
   - If the user did not specify a prefix, use `p` for process/control/monitoring apps and `u` for utilities or simulation helpers.
2. Generate the starting point.
   - New app: run `$MOOS_IVP_ROOT/scripts/GenMOOSApp_AppCasting <Name> <prefix> "<Author>"` from the project source directory.
   - Inspect existing apps as references. Copy an existing app when the user explicitly asks or when it is obviously the nearest local-project base.
3. Wire the build.
   - Read `references/app-build.md` before creating or repairing project-level CMake.
   - Preserve existing project CMake style when present.
4. Implement app behavior.
   - Read `references/app-patterns.md` for mail/config/iterate/AppCasting conventions.
   - Store the latest relevant mail in state; keep expensive, repeated, or state-combining work in `Iterate()`. Publish directly from `OnNewMail()` only for trivial acknowledgments or explicitly requested immediate reactions.
   - Validate message type before using `GetDouble()` or `GetString()`.
5. Update user-facing app metadata.
   - `showSynopsis()`
   - `showExampleConfigAndExit()`
   - `showInterfaceAndExit()`
6. Add or update mission config only if the task needs a runnable mission. Use
   `moos-ivp-mission-builder` for broader launcher, ANTLER, vehicle, or
   shoreside mission work.
   - Use `ProcessConfig = <AppName>` with realistic `AppTick` and `CommsTick`.
   - If only source was requested, an example `ProcessConfig` in `_Info.cpp` is
     enough. If a runnable sample mission was requested, include the
     `ProcessConfig` and the `pAntler` or launcher context that actually starts
     the app.
   - Add the app to `pAntler` or the mission launcher pattern only if the existing mission uses that style.
   - Ensure the launcher can find the built app binary. For external projects,
     prefer a minimal `pAntler` validation mission with a launcher-local
     `PATH=<project>/bin:$PATH` extension, or document the persistent shell
     setup that puts the project `bin/` on `PATH`.
7. Validate.
   - Configure/build the project or target when feasible.
   - Run the generated binary with `--help`, `--example`, and `--interface` as
     smoke checks when those options are supported.
   - If runtime config matters, validate through a normal `pAntler` launch with
     `ProcessConfig = <AppName>` rather than treating a direct binary run as
     equivalent.
   - If a mission was touched, launch only when the user asked for runtime validation or the change is risky enough to justify it.

## Reference Use

- Read `references/app-build.md` when the project build layout is missing, broken, or unfamiliar.
- Read `references/app-patterns.md` before implementing nontrivial app logic.
- Read `references/app-examples.md` when choosing a representative app to inspect in the resolved `MOOS_IVP_ROOT`.

## Validation Checklist

- App has a project build entry.
- App links only the libraries it actually needs, plus `apputil` for AppCasting and `mbutil` for common utilities.
- `OnNewMail()` handles or deliberately ignores subscribed mail without warning on `APPCAST_REQ`.
- `registerVariables()` lists every subscribed variable.
- `showInterfaceAndExit()` matches actual subscriptions/publications.
- Build succeeds, or the blocker is reported with the exact missing dependency/error.
- `--help`, `--example`, and `--interface` reflect the real app and do not
  crash when supported.
- Runtime config, when relevant, is verified through `pAntler` with
  `ProcessConfig = <AppName>`, not by direct app-by-path execution alone.
