# Mission Validation Reference

## Static Check

Run:

```bash
scripts/static_check_mission.sh <mission-dir>
```

This checks for the expected file set and common launcher/configuration hazards.
It supports both vehicle missions and shoreside-only missions, but it is still
structural. It does not prove launch arguments are forwarded into generated
targets.

## Generated Port Check

Run:

```bash
scripts/check_generated_ports.sh <mission-dir> --port_base=9100
```

This runs `launch.sh --just_make --nogui` with non-default ports and confirms
the generated targets reflect those ports. It catches mistakes that static grep
cannot, such as parsing `--veh_mport` without forwarding it into
`launch_vehicle.sh`. For the bundled two-vehicle pattern, it checks both named
vehicles rather than only the first generated vehicle target.

The checker cleans generated targets on exit unless `--keep-targets` is passed.
A printed `PASS` line and exit code `0` mean the non-default ports were
verified. Regenerate targets with `./launch.sh --just_make ...` or pass
`--keep-targets` if you need to inspect them afterward.

## Target Generation

From the mission directory:

```bash
./launch.sh --just_make --nogui 5
```

Then inspect:

```bash
ls targ_*.moos targ_*.bhv
rg 'ServerPort|Community|MOOSTimeWarp|Run =|behaviors' targ_*.moos
rg 'input = route|try_shore_host' targ_*.moos
rg 'Behavior =|name|condition|speed|point|polygon' targ_*.bhv
```

Target generation is necessary but not sufficient. It checks wrapper wiring and
`nsplug` syntax, but not live app validity.

## Runtime Check

Run live validation only when requested or when the change affects runtime
behavior:

```bash
./launch.sh --xlaunched --nogui 5
```

Prefer `--xlaunched` for automated validation so the shell remains available
for `uQueryDB`, listener checks, and teardown. Use interactive `uMAC` validation
only when the operator workflow itself is being checked.

Verify expected MOOSDB listeners, deploy manually if needed, then stop cleanly.
Do not report a runtime mission as clean if target generation worked but live
apps emit configuration warnings.

Do not treat `--xlaunched --nogui` exit status alone as a live validation pass.
Depending on the wrapper and terminal environment, launcher output may be
hidden and short-lived app failures may leave only MOOSDB processes behind. If
the full app stack is not visible through `uQueryDB` or `uProcessWatch`, run a
direct community-level check such as `pAntler targ_<community>.moos` on
isolated ports and inspect the app list and logs.

When running several `uQueryDB` probes in parallel, give them distinct client
names if the installed tool supports it, or run them serially. Default client
name collisions can make a healthy community look unstable.

Some validation helpers are intentionally quiet. A silent command with exit
code `0` is a pass only if the helper documents that convention; otherwise,
inspect the generated target or result file it was supposed to validate.

## Ideal Validation

For high-confidence mission validation, use this sequence:

1. Run the static checker.
2. Run `./launch.sh --just_make --nogui <warp>`.
3. Inspect generated targets for ports, communities, app blocks, behavior file
   names, pShare routes, GUI suppression, and helm behavior blocks.
4. Review launcher `--help` text after renaming vehicles, apps, ports, or
   default locations. Stale copied help output is a real usability bug even if
   target generation still works.
5. Launch on non-default ports with `--xlaunched --nogui`.
6. Use `uQueryDB` against every community to confirm MOOSDB uptime, expected
   clients, helm state, and key variables such as `NAV_X`, `NAV_Y`, and
   `IVPHELM_STATE`.
7. If the mission needs deploy/motion validation, apply the operator pokes or
   GUI-equivalent pokes and confirm the mission-specific state transition or
   movement.
8. Stop the mission and verify no listeners/processes remain on the mission's
   ports.
9. Use `moos-alog-analysis` on the generated `.alog` files to verify the
   mission ran as expected in post-processing.

The `.alog` pass should be mission-specific, but normally checks:

- expected apps posted evidence of life
- helm reached the expected states or modes
- expected vehicle navigation variables were posted
- expected node reports or bridged variables crossed communities
- deployed missions moved when movement was expected
- no unexpected early stop or missing variable pattern appears

For warning/error claims, pair `.alog` evidence with captured launcher/app
console output and logged `APPCAST`/helm variables. Target generation alone
cannot prove a warning-free live run, and `.alog` can only prove what the
mission actually logged.

## Common Failures

- top-level port arguments are parsed but not forwarded
- pShare overrides are accepted but generated `pShare` blocks still listen on
  default ports
- sublaunchers open their own `uMAC` because `--auto` was not passed
- `pHelmIvP` points at the wrong `targ_<vname>.bhv`
- `LatOrigin` / `LongOrigin` are missing
- `--nogui` suppresses `pMarineViewer` but leaves no replacement process where
  the mission expected one
- `clean.sh` deletes source files or kills unrelated processes
