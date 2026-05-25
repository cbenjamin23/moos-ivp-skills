# Eval Mission Style

An eval mission is a normal mission plus a self-grading contract. It should be
useful in three modes:

- `./launch.sh <warp>` for a human operator.
- `./launch.sh --just_make --nogui <warp>` for target generation checks.
- `./zlaunch.sh --max_time=<secs> <warp>` for headless automation.

## Ownership Boundary

The eval mission owns:

- startup flags for one scenario
- mission-local pass/fail variables
- `pMissionEval` conditions and `results.txt` columns
- `zlaunch.sh` as a thin automation wrapper
- compatibility with `xlaunch.sh`

The eval mission does not own:

- multi-case matrices
- patch selection loops
- parallel execution
- per-case temp directories
- expected-vs-actual aggregation
- benchmark archive/report logic

Those are harness responsibilities.

## Recommended File Set

```text
README.md
clean.sh
launch.sh
launch_vehicle.sh
launch_shoreside.sh
zlaunch.sh
meta_shoreside.moos
meta_vehicle.moos
meta_vehicle.bhv
plug_origin_warp.moos
```

For a single-community unit mission, the vehicle files may be absent. The same
evaluation rules still apply: `pMissionEval` should produce the verdict and
`zlaunch.sh` should remain thin.

## Launcher Boundaries

Avoid hard-coding AI product names, assistant names, or private machine owners
in generated file banners. Use the project or user-supplied author convention,
or omit author lines when there is no local convention.

Keep `clean.sh` boring. It should remove generated targets, sidecars, logs, and
temporary files. Do not move mission teardown, sleeps, `ktm`, or harness cleanup
into `clean.sh`.

Top-level `launch.sh` should own at most one interactive `uMAC` session. If it
launches vehicle and shoreside sublaunchers, pass `--auto` into sublaunchers so
they do not open nested `uMAC` sessions.

Avoid adding a `SIGTERM` trap that calls `kill -- -$$`. It can recurse when the
launcher kills its own process group. If a copied launcher already has unusual
signal handling, verify it in a generated target and live run instead of
copying it forward by habit.

Do not copy `AUTO_LAUNCHED` guards around `pAutoPoke`, `pMissionEval`, or
similar evaluator apps unless you have explicitly decided when those apps should
exist. If evaluator apps are intended in ordinary `launch.sh` runs, verify that
the top-level launcher propagates `--auto` or otherwise defines the guard so the
generated `targ_shoreside.moos` contains the expected apps.

## Result Shape

Keep `results.txt` easy for both humans and harnesses to parse:

```text
grade=pass form=waypoint_eval mmod=single_point eval=true wpt_done=true mhash=abcd1234
```

Use stable column names. Avoid long structured payloads unless no simple helper
variable can represent the result.

The contract is flexible: `grade=<pass|fail>` is required, and the remaining
fields should be the metrics that explain this mission's verdict. Recommended
fields like `form`, `mmod`, `eval`, `timeout`, and `mhash` are useful defaults,
not a reason to omit better domain metrics such as `cpa`, `collision`,
`node_count`, `heading_error`, `payload_ok`, or `process_count`.

Only `pMissionEval` should write the final grade row. Do not make `zlaunch.sh`
derive `grade=` from a generated target, a patch marker, `grade_hint`, or a
wrapper-side condition. If the mission cannot produce `grade=`, the wrapper
should report missing grade and exit nonzero.
