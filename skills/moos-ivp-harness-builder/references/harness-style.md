# Harness Style

A harness is a regression runner around one or more self-evaluating stem
missions. The stem mission decides `grade=pass` or `grade=fail` through
`pMissionEval`. The harness decides which cases to run, how to patch each temp
copy, and how to publish each case row. For ordinary harnesses, the published
row should be directly presentable:

```text
case=<case_name> grade=<pass|fail> eval=<true|false> <evidence fields...>
```

The harness should normally prepend `case=<case_name>` to the stem mission's
result row. It should synthesize a row only when the runner itself failed before
the mission could report a usable result, for example:

```text
case=<case_name> grade=fail reason=launch_error launch_rc=<rc>
case=<case_name> grade=fail reason=missing_result
```

Do not add a harness-owned `reason=` to ordinary mission failures. If
`pMissionEval` reports `grade=fail`, preserve the mission evidence fields that
explain what failed. Use `reason=` for runner failures unless the mission itself
chooses to emit a compact mission-owned reason.

Optional provenance fields such as `form=`, `mmod=`, and `mhash=` are useful but
not required. If both `case=` and `mmod=` are present, they should normally
match.

The stem mission must decide the grade through `pMissionEval`. A target file
field such as `grade_hint`, or a shell wrapper that echoes `grade=`, is not a
self-evaluating mission.

## Harness Owns

- case matrix documentation
- case-to-patch mapping
- per-case temp mission copies
- serial or wave execution
- per-case port blocks
- result publication
- runner-failure rows
- scoped teardown
- preserved workdirs for debugging

## Stem Mission Owns

- launchable mission files
- explicit startup initialization
- `pMissionEval` verdict
- `results.txt`
- `zlaunch.sh` compatibility with `xlaunch.sh`
- accepting forwarded ports and `--mmod`
- forwarding `--shore_mport`, `--veh_mport`, `--shore_pshare`,
  `--veh_pshare`, and `--mmod` from top-level launchers into sublaunchers
- using `nsplug -x` so harness-created `.moosx` and `.bhvx` sidecars are
  consumed during target generation
- expected-negative semantics: if a case is supposed to expose a bad condition,
  `pMissionEval` should report `grade=pass` when that bad condition is observed

Keep this separation strict. If harness code starts interpreting raw MOOS
traffic that `pMissionEval` could grade, the boundary is probably wrong. If
stem wrapper code manufactures `results.txt`, fix the stem before building the
harness.

Use `case_result=success|mismatch|error`, `expected=fail actual=fail`, or
similar wrapper verdicts only for legacy compatibility or when the harness is
explicitly testing failure machinery such as `pMissionEval`, `uMayFinish`, or
CLI return-code behavior.

## App-Level Vs Integration Harnesses

App-level harnesses should grade the app under test. Do not make an app-level
case pass or fail on an unrelated mission event such as vehicle arrival unless
arrival is part of the behavior being tested.

Moving/integration harnesses may grade mission outcome, encounter outcome,
arrival, obstacle interaction, or collision state because those outcomes are the
subject of the test.

For H02-style threshold families, prefer geometry-driven below/edge/above cases
with stock behavior parameters held fixed. Avoid defining the threshold by
changing behavior parameters such as `min_util_cpa`, `max_util_cpa`, or a broad
behavior patch. If the split only works by changing the behavior under test, it
is not a stable H02 threshold pattern.

If a harness must inspect a structured payload, keep that check narrow and
supplemental. Prefer a stem mission that normalizes the payload into a boolean
or scalar and writes the mission-owned grade.

For obstacle, contact, or geometry-heavy harnesses, also read the eval mission
builder's `scenario-and-grading.md`. Keep the scenario model realistic enough to
test the app or behavior path being claimed, and avoid copying CI reference
geometry blindly when a simpler or safer baseline exposes the same contract.

Real `moos-ivp-cicd` examples are good references, but their README prose may
lag behind the scripts. Trust current launch scripts, generated target files,
and live results over stale prose when the two disagree.
