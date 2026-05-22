# Harness Validation

Validate from smallest to largest.

For new or heavily changed harnesses, also run the adversarial checks in
`generated-harness-self-tests.md`.

## Stem First

```bash
cd <stem-mission>
<skills-root>/moos-ivp-eval-mission-builder/scripts/static_check_eval_mission.sh .
./zlaunch.sh --max_time=90 10
```

Do not debug the harness until the stem writes the expected `results.txt`.
Confirm that `pMissionEval`, not shell wrapper code, writes the `grade=` row.
The stem's `zlaunch.sh` may check for a missing grade, but it must not echo or
derive the final grade itself.

Also verify the stem contract:

```bash
./zlaunch.sh --just_make --shore_mport=9000 --veh_mport=9001 \
  --shore_pshare=9015 --veh_pshare=9016 --mmod=contract_check 10
```

Inspect generated targets for those ports and inspect launchers for `nsplug -x`
support before adding harness patches.

## One Case

```bash
cd <harness>
./zlaunch.sh --case=<case-token> --max_time=90
```

Confirm the harness output includes:

- case token
- mission grade
- `eval=` or other mission-owned verdict evidence when available
- runner-failure `reason=` if the mission did not produce a usable result
- original mission result columns

## Serial Suite

```bash
./zlaunch.sh --jobs=1 --port_base=9000
```

Serial mode should not depend on default ports.

Before trusting results, reconcile README case tokens with the script's
`CASES` / `ALL_CASES` list and `get_case_config`.

## Small Wave

```bash
./zlaunch.sh --jobs=2 --port_base=31000 --keep_workdirs
```

Inspect preserved workdirs to confirm each case has generated targets with
distinct MOOSDB and pShare ports.

Preserved workdirs should be under one harness-owned run root, not scattered in
system temp directories.

A one-case debug run may bypass the isolated temp-copy path in some harness
styles. Use a grouped run with preserved workdirs when validating port
isolation, sidecar consumption, or wave cleanup.

## Post-Run Hygiene

After serial and wave runs, check:

- generated targets consumed forwarded ports
- expected `.moosx` and `.bhvx` sidecars exist only in the intended workdirs
- no mission-owned MOOSDB, pShare, app, or viewer processes remain
- logs do not contain unexpected warnings that the mission grade masks
- no other harness batch is using an overlapping port range
- runtime summaries distinguish wall-clock time from MOOS time when reporting
  timing or benchmark results

Use `moos-alog-analysis` for targeted post-run evidence when aggregated case
results are not enough to diagnose a failure.

For ordinary harnesses, every selected case should produce exactly one row with
`case=` and `grade=`. Treat `grade=pass` as the case passing. Treat any other
grade as suite failure unless the harness is explicitly testing failure
machinery. Do not require `expected=`, `actual=`, or `case_result=` in new
harness output.

## Failure Debugging

If a wave-only failure occurs:

1. Preserve workdirs.
2. Inspect each case's `results.txt`.
3. Inspect generated `targ_*.moos` ports.
4. Run the failing case alone on a fresh `--port_base`.
5. Add a solo-wave exception only when the case is truly timing-sensitive.
