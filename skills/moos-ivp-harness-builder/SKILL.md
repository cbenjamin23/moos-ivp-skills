---
name: moos-ivp-harness-builder
description: "Build or repair multi-case MOOS-IvP test harnesses around self-evaluating stem missions: case matrices, per-case mission copies, result aggregation, serial or rolling parallel execution, port isolation, scoped teardown, and nspatch variants. Use moos-ivp-eval-mission-builder for stem missions."
---

# MOOS-IvP Harness Builder

## Overview

Use this skill for a harness that runs one or more self-evaluating stem missions
across multiple named cases. The stem mission should own the mission grade. The
harness should own case selection, patching, temp copies, port isolation,
rolling parallel execution, cleanup, and direct publication of per-case result
rows.

For the stem mission itself, use `moos-ivp-eval-mission-builder`. For ordinary
mission construction before evaluation plumbing, use `moos-ivp-mission-builder`.
For post-run `.alog` evidence, use `moos-alog-analysis`.

## Core Rules

- Start from a stem mission that runs headlessly and writes `results.txt` with a
  `grade=` column.
- Prefer placing harness directories at the repository root, alongside
  `missions/`, for example `harnesses/<harness_name>/` paired with
  `missions/<stem_mission>/`. In larger repositories, use optional family
  grouping for both sides, such as
  `harnesses/<family>_harnesses/HNN-<harness_name>/` paired with
  `missions/<family>_missions/<stem_mission>/`. Have the harness refer to stem
  missions with explicit relative paths. Other layouts are acceptable when
  project conventions or packaging require them.
- The stem mission must be a real eval mission: `pMissionEval` writes the
  `grade=` row. Do not accept a stem where `zlaunch.sh` or shell code
  synthesizes `grade=` from target files, patch markers, or harness knowledge.
- Keep case intent documented in the harness README under `Cases` or
  `Current Matrix`.
- Use exact case tokens in documentation and in `zlaunch.sh`.
- Keep case setup explicit. A shell `case` block mapping case name to patch
  files, fixture files, stem launch arguments, and intent is easier to audit
  than filename inference.
- When multiple cases reuse one stem but need different setup or evaluation
  criteria, express the differences in the case matrix and case-owned patch
  files, fixture files, or stem launch arguments.
- Keep `launch.sh` and stem wrappers human-facing. Put loops, temp copies,
  aggregation, and archives in harness code.
- Prefer mission-owned grades. The harness should normally prepend
  `case=<case_name>` to the mission result row and preserve the mission's
  `grade=pass|fail` as the case verdict.
- For expected-negative cases, make the stem `pMissionEval` pass when the
  expected negative evidence is observed. Do not encode those cases as
  `expected=fail actual=fail` unless the harness is explicitly testing failure
  machinery such as `pMissionEval`, `uMayFinish`, or CLI return semantics.
- Harness code should synthesize its own `grade=fail` rows only for runner
  failures, such as `reason=launch_error`, `reason=missing_result`,
  `reason=prepare_error`, `reason=missing_result_file`, or
  `reason=teardown_error`.
- Do not add a harness-owned `reason=` for ordinary `pMissionEval` failures.
  Preserve the mission evidence columns that explain the failure. A mission may
  report its own compact `reason=`, but the harness should not reinterpret it.
- Avoid new `case_result=success|mismatch|error` result formats for ordinary
  harnesses. Treat them as legacy compatibility or as a special pattern for
  tests whose subject is the failure machinery itself.
- Keep evaluation levels strict: app-level harnesses should grade the app under
  test; moving/integration harnesses may grade arrival, encounter outcome,
  collision state, or other mission outcomes.
- Expose `--case`, `--port_base`, `--keep_workdirs`, `--gui`, `--nogui`, and
  `--max_time` when the harness can support them. Expose `--jobs` only when it
  runs real backgrounded cases. For new generated harnesses, prefer Bash 5.1+
  rolling scheduling with `wait -p <pidvar> -n`, so the next pending case starts
  as soon as any active case finishes. Batch-barrier waves are a legacy fallback
  pattern, not the preferred default.
- Modern generated harnesses may require Bash 5.1+ for reliable rolling
  scheduling and PID-to-case bookkeeping. Use `#!/usr/bin/env bash`, add an
  early Bash version guard with a clear macOS/Homebrew message, and optionally
  re-exec a known Homebrew/Linuxbrew Bash before failing.
- Treat harness `--max_time` as a run-time ceiling override forwarded to each
  stem eval mission's `zlaunch.sh`; do not use it as harness-side grading
  logic.
- Default generated harnesses to `PORT_BASE=9000`. Use higher fresh bases only
  as explicit run-time overrides for automation or local sessions that may
  collide with ordinary missions in the `9000` range.
- Use headless mode as the default. Keep `--gui` available for an individual
  case when visual inspection is useful.
- For parallel execution, give each live case its own temp mission copy and
  port block. Do not patch or run through a shared stem directory while
  multiple cases are active.
- Create per-case temp mission copies under a harness-owned run root, not a
  generic system temp location. `--keep_workdirs` should preserve one auditable
  run tree beneath the harness directory.
- Use scoped teardown between cases and at harness exit. Prefer
  copying `assets/moos_scoped_teardown.sh` into the generated project as
  `<project-root>/scripts/moos_scoped_teardown.sh`, sourcing it from harness
  launchers, and calling `moos_scoped_teardown_stop_root` on the harness-owned
  run root or case directory. Do not use global `ktm`, `pkill`, or machine-wide
  cleanup as the normal path.
- If a case is timing-sensitive only when run in parallel, document it as a
  solo-slot case instead of disabling all parallelism.

## Workflow

1. Confirm the stem mission passes as a single eval mission.
   - run the eval mission static checker against the stem
   - `launch.sh` accepts and forwards `--shore_mport`, `--veh_mport`,
     `--shore_pshare`, and `--veh_pshare`.
   - launchers use `nsplug -x` so `.moosx` and `.bhvx` sidecars are consumed.
   - generated targets prove the forwarded ports and patches actually landed.
2. Define case tokens, case intent, and the mission-owned evidence each case
   should report.
3. Document the case matrix in `README.md`.
4. Decide whether each case needs patch files, fixture files, stem launch
   arguments, or no setup changes.
5. Build `zlaunch.sh` around:
   - argument parsing
   - case selection and setup mapping
   - optional patch overlay application
   - `run_case`
   - serial and rolling execution
   - result aggregation
   - cleanup traps
6. Add the teardown helper asset to the generated project if there is not
   already an equivalent root-scoped helper.
7. Implement port forwarding from harness to stem mission and verify generated
   targets reflect those ports.
8. Add `--keep_workdirs` for debugging preserved temp copies.
9. Validate one case, `--jobs=1`, then a small rolling run on a fresh
   `--port_base`.

## Reference Use

- Read `references/harness-style.md` for the overall architecture.
- Read `references/case-matrix.md` before writing README case docs.
- Read `references/nspatch-workflow.md` before adding patch overlays.
- Read `references/ports-and-parallelism.md` before implementing `--jobs` or
  `--port_base`.
- Read `references/generated-harness-self-tests.md` before reporting a new or
  heavily changed harness as trustworthy.
- Read `references/validation.md` before reporting a harness as done.
- Read `references/timing-and-benchmarking.md` before tuning `--jobs`, sleeps,
  `--max_time`, or benchmarking rolling runs.
- Read `references/scoped-teardown.md` before writing cleanup logic.
- Read `references/example-harness-zlaunch.md` for a compact runner skeleton.
- Reuse `assets/moos_scoped_teardown.sh` by copying it into generated harness
  projects as `<project-root>/scripts/moos_scoped_teardown.sh` when they do not
  already provide an equivalent root-scoped helper.
- Run `scripts/static_check_harness.sh <harness-dir>` for a structural check.

## Validation Checklist

- Stem mission passes alone with `./zlaunch.sh --max_time=<secs>`.
- Stem mission passes `moos-ivp-eval-mission-builder` static validation; the
  harness static checker alone is not enough.
- Harness README has a `Cases` or `Current Matrix` section with exact case
  tokens and prose intent.
- `./zlaunch.sh --case=<case> --max_time=<secs>` works for at least one nominal
  case and one expected-negative case if the suite has both.
- If `--jobs` is exposed, `./zlaunch.sh --jobs=1 --port_base=<base>` works, and
  a rolling run with `--jobs=2` or higher uses distinct temp directories and
  distinct port blocks. New generated harnesses should start the next pending
  case whenever an active case finishes, not wait for an entire batch barrier.
- Aggregated results include `case=` and the mission's original result columns,
  especially `grade=` and useful evidence fields such as `eval=`,
  `warning_count=`, `expected=`, `observed=`, or case-specific scalars.
- `case=` is the harness row key. Harness case setup should be explicit in the
  case matrix, patch files, fixture files, or stem launch arguments. `form=`,
  `mhash=`, and mission-owned evidence columns may be preserved as provenance.
- Ordinary case success is `grade=pass`. Any row with `grade!=pass` should make
  the harness exit nonzero unless the harness is explicitly testing failure
  machinery.
- Harness-owned failure rows use `case=<case> grade=fail reason=<runner_reason>`
  and preserve launch return codes or setup evidence when available.
- Selected runs produce one normalized result line for every selected case,
  including setup errors and intentional failures.
- A selected run that produces zero case rows is a harness failure and should
  exit nonzero with a clear diagnostic. This catches portability bugs where the
  case loop never actually ran.
- New generated harnesses that implement rolling scheduling should require Bash
  5.1+ and check that requirement near the top of `zlaunch.sh`. For legacy
  portable harnesses that intentionally target macOS system Bash 3.2, avoid
  `mapfile`, `readarray`, associative arrays, `wait -n`, and `wait -p`.
- `--keep_workdirs` preserves enough files to inspect generated targets and
  `results.txt`.
- Preserved workdirs show generated targets using distinct forwarded ports and
  any intended `.moosx` / `.bhvx` sidecars.
- No harness path relies on global `ktm`, `pkill`, or `killall`.
- Harness cleanup uses a root-scoped teardown helper or an equivalent recorded
  PID cleanup path; generated harnesses should not invent broad process cleanup.
- A teardown failure is visible, makes an otherwise successful run fail, and
  preserves the affected run root for inspection.
- Logs do not contain unexpected warnings hidden by case aggregation.
