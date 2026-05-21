---
name: moos-ivp-eval-mission-builder
description: Build or repair one self-evaluating MOOS-IvP mission. Use when creating headless-capable mission folders with explicit startup initialization, pMissionEval pass/fail checks, results.txt output, uMayFinish completion through xlaunch.sh, zlaunch.sh automation, scoped teardown, and validation for a single test scenario. Do not use for ordinary operator missions or multi-case harness orchestration.
---

# MOOS-IvP Eval Mission Builder

## Overview

Use this skill for one self-evaluating mission folder: a normal MOOS-IvP mission
with an added single-run grading contract. The mission should still be readable
and runnable by a person, but it must also run headlessly, decide pass/fail
inside the mission, write `results.txt`, and finish through the shared
`xlaunch.sh` / `uMayFinish` path.

For ordinary mission layout, use `moos-ivp-mission-builder` first. For multi-case
matrices, patch sweeps, parallel runs, or expected-vs-actual aggregation, use
`moos-ivp-harness-builder`. For post-run `.alog` evidence, use
`moos-alog-analysis`.

## Core Rules

- Start from an ordinary mission that already launches cleanly. Prefer the
  `moos-ivp-mission-builder` baselines or an existing nearby mission family.
- Add only the evaluation plumbing needed for one scenario:
  optional `pAutoPoke`, optional `uTimerScript`, `pMissionEval`,
  `results.txt`, and a thin `zlaunch.sh`.
- Keep `launch.sh` human-facing. It may accept `--xlaunched`, `--nogui`,
  `--mmod`, and port overrides, but it should not contain case loops or result
  aggregation.
- Keep `zlaunch.sh` thin: parse automation arguments, truncate `results.txt`,
  call shared `xlaunch.sh`, then run only scoped cleanup if a local helper is
  available.
- Let `xlaunch.sh` own `uMayFinish` and the timed wait/stop contract. Do not
  duplicate that lifecycle in mission-local wrappers.
- Do not synthesize `grade=` or write the final result row from `zlaunch.sh`,
  `launch.sh`, or target-file parsing. `pMissionEval` must own the verdict and
  write `results.txt`; wrappers may only truncate, launch, wait, validate
  presence of `grade=`, and clean up.
- Prefer `pAutoPoke` to seed deploy and evaluation variables in moving
  missions. Unit-style evals may use `uTimerScript` or the app under test for
  readiness when there is no vehicle/deploy lifecycle. Do not put pass/fail
  logic in `pAutoPoke`.
- Use `pMissionEval` as the primary verdict owner. Prefer mission-level booleans
  or simple scalar checks over harness-side parsing of raw MOOS traffic.
- Keep `results.txt` scalar and parseable. The only hard schema requirement is
  `grade=<pass|fail>`; fields such as `form=`, `mmod=`, `eval=`, `timeout=`,
  domain facts, and `mhash=` are recommended evidence, not a mandatory metric
  set.
- If a vehicle-local variable is graded shoreside, bridge it explicitly through
  the vehicle broker and shoreside broker.
- For GUI-capable eval missions, keep normal operator buttons available. Do not
  force appcast/realmcast viewer modes unless the evaluation scenario needs it.
- Do not add `--case`, `--jobs`, temp mission copies, per-case port blocks, or
  expected-vs-actual aggregation here. Those belong to the harness builder.

## Workflow

1. Confirm the base mission launches and generates targets.
2. Identify the smallest mission-owned pass/fail signal.
   - unit-style app variable
   - behavior end flag
   - arrival/collision/encounter outcome
   - load/process/host info signal
3. Add evaluation state to the relevant `.bhv` or app config.
4. Bridge graded vehicle-local variables to shoreside when needed.
5. Add `pAutoPoke` or an equivalent explicit initializer for deploy and
   evaluation variables.
6. Add `pMissionEval` with one lead condition, clear pass conditions,
   `result_flag = MISSION_EVALUATED = true`, and `report_file = results.txt`.
7. Add or update `zlaunch.sh` to call `xlaunch.sh --max_time=<secs>`.
8. Add or update `README.md` with scenario, grading signal, and run commands.
9. Validate target generation, then run the headless cycle and inspect
   `results.txt`.

## Reference Use

- Read `references/eval-mission-style.md` for boundaries and file layout.
- Read `references/evaluator-apps.md` before wiring `pAutoPoke` or
  `pMissionEval`.
- Read `references/scenario-and-grading.md` before grading obstacles, contacts,
  moving/integration outcomes, or structured payloads.
- Read `references/zlaunch-xlaunch.md` before editing automation wrappers.
- Read `references/validation.md` before reporting an eval mission as done.
- Copy `assets/eval-single-vehicle/` when a concrete minimal moving example is
  useful.
- Run `scripts/static_check_eval_mission.sh <mission-dir>` for a quick
  structural check.

## Validation Checklist

- `./launch.sh --just_make --nogui <warp>` succeeds.
- Generated targets contain `pMissionEval`, explicit initialization
  (`pAutoPoke`, `uTimerScript`, or an app-owned producer), and any evaluator
  apps needed for reported columns such as `pMissionHash`.
- Generated targets include bridged graded variables if the verdict depends on
  vehicle-local posts.
- `./zlaunch.sh --just_make <warp>` succeeds when `xlaunch.sh` is on `PATH`.
- Headless `./zlaunch.sh --max_time=<secs> <warp>` exits cleanly.
- `results.txt` contains one parseable result line with `grade=`.
- Runtime warnings are either eliminated or surfaced in `results.txt` with an
  explicit choice about whether they affect the verdict.
- No mission wrapper uses global `ktm`, `pkill`, or unrelated cleanup.
- GUI runs retain normal operator controls unless the user requested a
  headless-only mission.
